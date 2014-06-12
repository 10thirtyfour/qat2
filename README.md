Querix automated tests runner
=============================

This is Querix internal tool for running and reporting various kinds of tests
automatically. The library tracks dependencies between tests. The system may
be separated in core parts and extensions. At the moment they all live in
single node package but may be divided into several parts in future.

Minimal configuration may be used alone but it is more usable with predefined
set of extensions. There are many ways to extend we framework. The package
includes (or may include in future where marked) following extensions:

* scheduler extensions 
    - running several tests in parallel while keeping sequential
       execution in case if this is required by specific tests (e.g.
       tests which changes shared DB state)
    - distributed tests execution *near future*
* test engines
    - [Selenium WD][shqwd] based browser's tests
    - exit code check
        + Lycia installer
        + qbuild
        + Lycia deploy
    - headless mode
    - web services based testing *near future*
    - UI automation *near future*
* reporting
    - aggregation
    - skype output
    - performance check

Required skills
---------------

For minimal core parts usage following skills are required:

* JavaScript
* [CoffeScript][coffee] (optional)
* [lodash][] (optional)
* promises concept and implementation using [Q][] library
* [nodejs][nodejs]
    - [npm utility][npm]
    - [base modules][nodeapi]

Corresponding skills are required additionally for various extension modules,
e.g. for writing [Selenium WD][wdapi].

Some tests engines doesn't require programming skills at all, e.g. headless
tests engine.

Core
----

Core part's responsibilities:

* load configurations
* load required QAT modules
* track tests dependencies 
* initialize tests execution 

At start up the framework initializes single `Runner` object which stores
all contextual information for this tests run.

The configuration files and QAT modules have the same interface. They are
simple CommonJS ([nodejs][]) module files which exports a single function.
The module is imported using `require` function and it is called immediately passing the
global `Runner` function as `this` argument. The modules are free to do
whatever they wont this that `Runner` object. In most cases this is
registering new tests or adjusting some configuration option by means of
calling specific methods of `Runner` object.

After initializing the global Runner object the framework reads
configuration files if they are exist in following order. 

1. `./config.*`
2. `./config-{HOST}.*`
3. `./config-{USER}.*`
4. `./config-{HOST}-{USER}.*`
5. `~/.qat.*`
6. `$QAT_CONFIG` - environment variable
7. file given as command line argument --config=<filename>
8. Command line

The extension may be either `.js` or `.coffee`.

Each configuration file (steps 1-7) are expected to be CommonJS module
which exports a single function without arguments, where `this` points
to global `Runner` object. The function is free to do whatever it wants to
do with that runner object but because that functions are called in
unspecified order it may rely only on a small `Runner` interface. There are
two actions this top function may perform, namely changing configuration
options and/or loading test modules. Test module has dependency information
and they are executed in order respecting the dependencies. Modules
interface is discussed latter. 

Configuration QAT modules are loaded first so there is nothing other loaded
to configure. And moving configuration to after that modules loading
doesn't help much because they may load as result of some test execution.
Like globLoader module which looks up and loads other modules during its
execution.

So configuration files do properties settings in special `opts` field of
the global runner. On loading QAT modules the modules is merged with
[lodash][] `merge` function with the same name field of `opts` object.
Thus it is possible to provide options for each QAT module. Core part isn't
involved further into options handling.

It is possible to call any method of runner inside configuration files too,
for more complex configuration. But since no modules are loaded in the time
of configuration execution the only useful operation is again registration
of test module. And during execution of that module it is possible to
continue configuration for other modules specified in dependencies list.

Command line arguments are parsed using [optimist][] library and the `opts`
object is simply extended with parsed parameters. This way users may change
any simple option they want during invocation. It may be not convenient
because no validation is performed. And if there is even simple spelling
mistake in arguments it will be silently ignored. In *near future* special
validating interface will be added for tests.

Check *config.coffee* for mode details about configuring test runs.

See `runner.coffee` for `Runner` object interface documentation.

The QAT modules are loaded from following locations inside the package:

1. engines
2. passes
3. scheduler

During configuration stage the list may be adjusted by changing
`Runner.dirs` list.

During loading each module posts test using `post` function. The test
description contains following fields:

* `name` **required** - unique name of the test, the system will exit
  immediately without attempts to run tests in case if it encounter
  duplicate name. To avoid duplicates hierarchical ($-separated names)
  is to be used (e.g. `headless$querixtest$test_something$log1`), if the
  test is loaded by `globLoader` test name is not required and derived
  from path (see `globLoader` description for details).
* `promise` **required** - a promise object based on [Q][] library. The
  promise eventually should fulfill some value or rejects with some reason.
  In most cases these are correspondingly test's pass and fail.
* `before` *optional* - either list or comma-separated string specifying
  test cases which should be executed *before* this test case.
* `after` *optional* - the same like `before` but specify the tests is
  to be executed *after* this test case. This doesn't seem to be useful
  so probably **it may be removed**.
* `tags` *optional* - an object there each field is a kind of mark to be
  used in reporting or for adjusting test execution
* `disabled` *optional* - if the module is disabled, this option (like any
  other) may be changed during configuration, thus it is possible to
  disable or enable some tests which may be disable or enabled by default.
* any other test engine specific field.

After all modules are loaded the core framework gets values of promises
of each test in topological order of dependency relation. If the promise
is fulfilled the test suite is considered passed and failed if it is
rejected.

In that minimal configuration the test is simply a promise object with [Q][]
library interface. If the promise is fulfilled the test is considered passed
or if rejected it is failed. The library may also report status changes via
the promise's `notify` callback.

Any option of test definition may be changed during configuration. The most
typical use case is disabling some test. For example we may disable globing
module simply by command:

    $ qat --tests.globLoader.disable

This will just set disable field in test description object.

There is a few special nodes:

 * `setup` - first node to execute, every others depend on it.
 * `run` - all configuration is performed between `setup` and this node,
   after it only real tests run, though it is not strict limitation.
 * `done` - last node in the graph, depends on all other tests.

If test description has `setup` field set to `true` it will be placed between
`setup` and `run` nodes, or after `run` otherwise.

Extensions
----------

The core framework doesn't do much useful. Other facilities can be easily
added by means of simple extension API. An extension module is simply raw
test module described before. But instead of performing tests the modules
simply mutate current system configuration. The modules have dependencies
as many other modules. So for test to enable some extension it simply should
be included in `after` list. And for test system user that extension may be
enabled/disabled via user's configurations. 

There is a special module called "setup". The module will be executed only
if it depends directly or indirectly on that module. This is needed for
avoiding execution of extension module if it isn't required by any test
currently requested to run.

Loading test files
------------------

There is a simple extension for traversing folders and loading test cases.
It's called `globLoader` and it depends on [glob][] node library for
searching files in specified folders. Other modules may register glob
patterns by means of `regGlob` function of that module. Note the
`globLoader` module should be loaded in the moment of registration so the
only way to register is to use another test module which depend on
`globLoader`.

See `src\tests\node-modules-index.coffee` for example. It simply loads all
files recursively what ends by `-index` with extension `*.js` or `*.coffee`
and treats them as QAT module.

All globs modules are stored in `items` field of `globLoader` description
object and may be accessed as usual by path `tests.globLoader.globs`.

The glob description may have following fields:

* name **required** - unique glob name
* pattern **required** - [minimatch][] pattern or pattern's list
* disabled *optional* - the same like disabled for test description but
  for disabling some particular glob.
* root *optional* - root folders (may be list or PATH like list of folders)
  by default is taken from root field of `globLoader` which in turn is taken
  from `QAT_TESTS_ROOT` environment variable or default value is ".". This
  of course may be overridden in configuration file or with command line
  argument (e.g. for global one `--globLoader.root=<....>` or for
  node modules loader `--globLoader.items.node$modules.root=<...>`.
* parseFile **required** - takes file name as input, parses it and perform
  the action required needed for this kind of file, returns promise.
  * For node module it just does `require` for the file and treats result
    as a single function which receives `runner` object as the `this`
    argument.
  * For headless logs it may parse log's header and do specific for that
    mode registrations.

Glob object description (`runner.tests.globLoader`) may be further
configured.

There are `disable.root` and `disable.pattern` fields. It is possible
to disable specific pattern or root folder by setting corresponding fields
there.

By means of `only.file.pattern` field loaded modules may be even further
filtered, this way it is possible to load only single test module. But if
it depends on some other test in some other module which is not loaded the
system won't run. For this is to work there is other facilities
*near future* which load all test modules but executes only specified.

If test doesn't have name it will be derived by `globLoader` from name
pattern's name and path separated by $-sign for first registered test.
For next test cases `$<test number>` is appended. Note however this will
only work for synchronously added tests. Though it is better to give
explicit name for tests if they are referred somewhere else.

Parallel execution
------------------

The dependencies are in fact direct acyclic graph (DAG). It partitioned
into levels of dependencies. Each level may be executed in parallel. There
are 2 ways to do so. We either run specified amount of promises
asynchronously or we fork another process with crawling workers. It is a
subject of 2 corresponding extensions.

For some test cases we cannot use parallel execution. For example if tests
use some shared database. In this case we have another extension which
serializes DAG parts where needed.

Since all tests are written using asynchronous facilities we can start several
of them simultaneously. This is done using `async` plugin. It is disabled by
default. So to enabled it just unset `disabled` option for it, i.e.

    $ qat --no-async.disabled

Number of threads may be changed by its `maxThreads` parameter, i.e.

    $ qat --no-async.disabled --async.maxThreads=20

Clustering
----------

TODO:

Reporting
---------

The system core uses [winston][] library. It supports quite wide range of various
transports. So for example for local test run just console duplicated to file
may be just enough, but for distributed tests where several platforms are tested
in parallel we need to gather all data in some centralized location where it may
be quickly analyzed. That to be implemented in *near future* but likely it will
be [couchdb][] instance. This way we may log other tests not dependent on this
framework too, all it needs is to use [winston][] library which sends testing
messages using predefined format.

There is also transport which outputs logs to centralized web-applications for
nicely exposing logs, for example [logio][winston-log.io] which will likely will
be our solution for examining logs.

Note however, the system should not be strictly dependent on any centralized
services, it should be easy to run tests on local machine without internet
connection and without any setup efforts.

There is a `logger` plugin which extends the global `runner` object and each test
description with following methods:

* `trace` - outputs debug information, disabled by default
* `info` - just adds some information about the test
* `fail`
* `pass`

This is just custom [winston][] levels and have the same interface like default
ones.

Each message also contains additional information, called meta-data. This may be:

* test name
* fail reason
  * logs diff for headless tests
  * console output from compilation
  * screen shots difference (as image)
* stack trace
* performance data
  * CPU time (user/kernel)
  * memory
  * total time spend
* platform
  * RDBMS (may be several)
  * locale (system and DB)
  * logged user
  * browser (may be many)

The system automatically augments messages with test names and some other plugin
may augment it even further with platform data and performance data. This makes
final tests as simple as possible with only testing logic in place.

The logger plugin is initialized in top-level function and its `promise` function
simply does nothing, this means the parameters may still be changed from con fig
but not during execution of some other plugin.

Everything discussed above just records information about each test invocation.
This has little value for quick team response because such logs are typically
huge and require hours to analyze. This is to be done automatically by means of
report aggregates which are also part of the system. He we make an exception and
we don't make them to be just another module with the same interface. The
aggregating module doesn't receive the global runner instance and all the other
faculties other tests typically access via that object. For example obviously
we cannot log anything during aggregation because this changes log which is
analyzed at the time.

But there is more significant reason for another interface. There are two main
ways for aggregation, namely:

* online -  here results are collect during tests execution, each message is
  handled in the time of arrival updating corresponding counters
* offline - no results are aggregated during tests execution, but only after,
  then we have full data base of test results

So if some users runs tests locally they get results immediately without accessing
data bases, the results may be even examined if system isn't yet finished working.
But handing that in distributed system may quickly became a nightmare. It is also
possible to query for more information using such offline queries. Still it is
easy to get current state of currently running system querying partial state of
log's DB. This is called temporary and permanent views in [couchdb][] but in this
system it is more a distinction between reporting performed by the testing system
and by DB engine.

So reporting is another highly isolated part. The same JavaScript for queries may
run in context of NoSQL DB (such as [couchdb][]) and in context of our core
`runner`. This way the runner won't be always available. So we restrict aggregates
interface to pure part where they only manipulate and collect data. 

The most obvious solution for this is [MapReduce][] module. Where even distributed
DBs may be examined. But for the first version we consider only centralized store
while still keeping [MapReduce][] based interface for JavaScript queries.

For simplifying the system we implement simplified version of
[CouchDB views][couchview] in our system for online aggregation without [couchdb][]
requirements by default reduce function is just `_sum`, and map function does
correct key/value emitting there key is compound list value with tags from more
to less specific. This along with report generator is done in `aggregator` plugin.
The MapReduce queries are defined in its queries field. By default there is one
report which simply counts test cases and groups them by pass/fail, kind, and test
name keys. User can add another reports using configuration facilities. The same
functions may be used like views in [couchdb][]. The reduce interface is simplified
so the queries shouldn't use `keys` and `rereduce` parameters in reduce function
to make the query portable. Reporting only supports atomic parameters on value
side.

FAQ
---

###Q: How to run single test.###
A: It is possible to load only test cases specified by pattern:

    $ qat --globLoader.only.file.pattern="sleep*sync*"

###Q: How to get more verbose output.###
A: Logger options are defined in `logger` plugin, in `transport` field for each
transport with [winston][] properties for that transport, so to enable trace
output in console:

    $ qat --logger.transports.console.level=trace

###Q: How to run tests in parallel###
A: Use `async` plugin, which is disabled by default. I.e.

    $ qat --no-async.disabled




[coffee]: http://coffeescript.org/ "CoffeeScript language"
[nodejs]: http://nodejs.org/ "Node.js - JavaScript runtime"
[npm]: https://npmjs.org/doc/ "Node Packaged Modules"
[nodeapi]: http://nodejs.org/api/ "Node.js API"
[Q]: https://npmjs.org/package/q "A library for promises"
[shq]: http://www.seleniumhq.org/ "Selenium - Browser automation tools"
[shqwd]: http://www.seleniumhq.org/projects/webdriver/ "Selenium Web Driver"
[wdapi]: http://code.google.com/p/selenium/wiki/WebDriverJs "WD node API"
[lodash]: http://cpettitt.github.io/project/graphlib/latest/doc/index.html "lodash reference"
[optimist]: https://npmjs.org/package/optimist "Light-weight option parsing with an argv hash"
[dag]: http://en.wikipedia.org/wiki/Directed_acyclic_graph "Direct acyclic graph"
[tred]: http://en.wikipedia.org/wiki/Transitive_reduction "Transitive reduction"
[winston]: https://npmjs.org/package/winston "A multi-transport async logging library for Node.js"
[couchdb]: http://couchdb.apache.org/ "Apache CouchDB"
[MapReduce]: http://en.wikipedia.org/wiki/MapReduce "Map Reduce programming model"
[logio]: https://npmjs.org/package/winston-logio "A Log.io transport for winston"
[couchview]: http://docs.couchdb.org/en/latest/couchapp/views/intro.html "CouchDB Guide to views"
