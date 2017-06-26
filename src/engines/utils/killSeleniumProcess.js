const ps = require('ps-node');
const { exec } = require('child_process');

// Firefox requires kill selenium process
const killProcesess = ({ commands, spawnCommand = 'start /MIN c:/qat/firefox.bat' } = {}) => {
  const findSeleniumProcess = name => (err, result) => {
    if (err) console.log(err);
    // console.log('matched process: ', result)
    let seleniumProcess;
    // method Array.prototype.find doesn't working here
    let seleniumFind = result.forEach(elem => {
      if (elem.arguments.length && !seleniumProcess) {
        elem.arguments.forEach(arg => (arg.includes('selenium') ? (seleniumProcess = elem) : null));
      }
    });
    console.log(seleniumProcess);
    if (!~seleniumProcess) {
      console.log(`${name} process not found`);
      return;
    }
    const { pid } = seleniumProcess;

    console.log(`process ${name} was founded! with PID:${pid}`);
    try {
      ps.kill(pid, err => {
        if (err && err.message && !err.message.includes('timeout')) {
          throw new Error(err);
        }
        console.log('Process pid: %s has been killed!', pid);
        console.log(`Starting new ${name} process`);
        exec(spawnCommand);
        console.log(`new process started`);
      });
    } catch (e) {
      console.log(e);
    }
  };
  ps.lookup({ command: 'java' }, findSeleniumProcess('selenium'));
  // ps.lookup({ command: 'geckodriver' }, findSeleniumProcess('gecko'));
};
// killProcesess();
module.exports = killProcesess;
