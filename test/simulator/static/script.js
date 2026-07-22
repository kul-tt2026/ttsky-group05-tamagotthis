const socket = io();

document.addEventListener("keydown", function(e) {
    socket.emit("key", {
        key: e.key,
        pressed: true
    });
});

document.addEventListener("keyup", function(e) {
    socket.emit("key", {
        key: e.key,
        pressed: false
    });
});