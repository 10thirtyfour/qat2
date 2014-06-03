module.exports = function() {
    var Q = this.Q;
    var logger = this.logger;
    this.reg({
        name: "a",
        after: ["b","c"],
        data: { kind: "sample" },
        promise: function() {
            return Q.delay(1000).then(
                function() {
                    logger.info("TEST A");
                    return true;
                });
        }});
    this.reg({
        name: "b",
        after: ["c"],
        data: { kind: "sample" },
        promise: function() {
            return Q.delay(1000).then(
                function() {
                    logger.info("TEST B");
                    throw new Error("BOOM!!!");
                    return true;
                });
        }});
    this.reg({
        name: "c",
        data: { kind: "sample" },
        promise: function() {
            return Q.delay(1000).then(
                function() {
                    logger.info("TEST C");
                    return true;
                });
        }});
    this.reg({
        name: "d",
        after: [],
        data: { kind: "sample" },
        promise: function() {
            return Q.delay(1000).then(
                function() {
                    logger.info("TEST D");
                    throw new Error("BANG!");
                    return true;
                });
        }});
};

