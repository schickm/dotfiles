module.exports = {
    reporter: function(errors) {
        errors.forEach(function(m) {
            console.log(`${m.file}:${m.error.line}:${m.error.character}: error: ${m.error.reason}`);
        });
    }
};
