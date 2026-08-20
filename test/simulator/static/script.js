const socket = io();

socket.on("connect", () => {
    console.log("Socket.IO connected", socket.id);
});

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

// Play audio in browser.

let audioContext = null;
let oscillator = null;
let gain = null;

document.getElementById("startAudio").onclick = async () => {
    audioContext = new AudioContext();

    await audioContext.resume();

    gain = audioContext.createGain();
    gain.gain.value = 0.1;
    gain.connect(audioContext.destination);

    oscillator = audioContext.createOscillator();
    oscillator.type = "square";
    oscillator.frequency.value = 0;
    oscillator.connect(gain);
    oscillator.start();

    console.log("Audio enabled");
};

socket.on("audio", (data) => {
    console.log("Received frequency:", data.frequency);

    if (oscillator) {
        oscillator.frequency.setValueAtTime(
            data.frequency,
            audioContext.currentTime
        );
    }
});