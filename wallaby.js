module.exports = function () {
    return {
        files: [
            'src/**/*.coffee'
        ],

        tests: [
            'test/**/*.coffee'
        ],

        env: {
            type: 'node'
        }
    };
};