console.log("JS loaded");

function Chronometer() {
    var t = React.useState("00:00:00.000");
    var time = t[0];
    var setTime = t[1];

    var r = React.useState(false);
    var running = r[0];
    var setRunning = r[1];

    var l = React.useState([]);
    var laps = l[0];
    var setLaps = l[1];

    var ref = React.useRef({ start: 0, base: 0, iv: null });

    function fmt(s) {
        var ms = Math.round(s * 1000);
        var h = Math.floor(ms / 3600000);
        var m = Math.floor((ms % 3600000) / 60000);
        var s2 = Math.floor((ms % 60000) / 1000);
        var r2 = ms % 1000;
        return (h < 10 ? "0" : "") + h + ":" +
               (m < 10 ? "0" : "") + m + ":" +
               (s2 < 10 ? "0" : "") + s2 + "." +
               (r2 < 100 ? "0" : "") + (r2 < 10 ? "0" : "") + r2;
    }

    function tick() {
        var e = ref.current.base + (Date.now() - ref.current.start) / 1000;
        setTime(fmt(e));
    }

    function begin(bt) {
        ref.current.start = Date.now();
        ref.current.base = bt;
        if (!ref.current.iv) {
            ref.current.iv = setInterval(tick, 100);
        }
    }

    function end() {
        if (ref.current.iv) {
            clearInterval(ref.current.iv);
            ref.current.iv = null;
        }
    }

    function fetchThen(url) {
        fetch(url).then(function(x) { return x.json(); }).then(function(d) {
            setTime(d.time_str);
            setRunning(d.running);
            setLaps(d.laps || []);
            if (d.running) begin(d.time);
            else end();
        }).catch(function(e) { console.error("ERR", url, e); });
    }

    React.useEffect(function() {
        fetchThen("/api/state");
        return end;
    }, []);

    function clickHandler(label, url) {
        return function(ev) {
            console.log("Clicked", label, url);
            fetchThen(url);
        };
    }

    var style = {
        wrap: { background: "#1c1c1c", borderRadius: "16px", padding: "30px",
                width: "420px", margin: "0 auto", boxShadow: "0 8px 30px rgba(0,0,0,0.3)" },
        status: { color: running ? "#4caf50" : "#ff6b6b", fontSize: "1rem",
                  fontWeight: "600", margin: "10px 0", textAlign: "center" },
        time: { color: "#fff", fontSize: "3rem", fontWeight: "300",
                fontFamily: "monospace", margin: "20px 0", textAlign: "center" },
        btn: { padding: "12px 28px", fontSize: "1rem", border: "none",
               borderRadius: "8px", cursor: "pointer", margin: "5px", fontWeight: "600" },
    };

    var kids = [];

    kids.push(React.createElement("h1", { key: "t", style: { color: "#fff", fontSize: "1.1rem", fontWeight: "400", margin: 0, textAlign: "center" } }, "Chronometer"));
    kids.push(React.createElement("div", { key: "s", style: style.status }, running ? "RUNNING" : "STOPPED"));
    kids.push(React.createElement("div", { key: "d", style: style.time }, time));

    var btns = [];
    if (running) {
        btns.push(React.createElement("button", { key: "ST", style: Object.assign({}, style.btn, { background: "#ff6b6b", color: "#fff" }), onClick: clickHandler("Stop", "/api/stop") }, "Stop"));
        btns.push(React.createElement("button", { key: "LA", style: Object.assign({}, style.btn, { background: "#4caf50", color: "#fff" }), onClick: clickHandler("Lap", "/api/lap") }, "Lap"));
    } else {
        btns.push(React.createElement("button", { key: "ST", style: Object.assign({}, style.btn, { background: "#4caf50", color: "#fff" }), onClick: clickHandler("Start", "/api/start") }, "Start"));
        btns.push(React.createElement("button", { key: "RE", style: Object.assign({}, style.btn, { background: "#d4d4d2", color: "#333" }), onClick: clickHandler("Reset", "/api/reset") }, "Reset"));
    }
    kids.push(React.createElement("div", { key: "b", style: { textAlign: "center" } }, btns));

    if (laps.length > 0) {
        kids.push(React.createElement("h3", { key: "lh", style: { color: "#aaa", marginTop: "20px", fontSize: "0.85rem", textTransform: "uppercase", textAlign: "center" } }, "Laps"));
        laps.forEach(function(lap, i) {
            kids.push(React.createElement("div", { key: "l" + i, style: { display: "flex", justifyContent: "space-between", color: "#ccc", padding: "6px 10px", fontFamily: "monospace", fontSize: "0.9rem" } },
                React.createElement("span", null, "Lap " + (i + 1)),
                React.createElement("span", null, lap.cumulative_str + " (+" + lap.split_str + ")")
            ));
        });
    }

    return React.createElement("div", { style: style.wrap }, kids);
}

console.log("Rendering...");
ReactDOM.createRoot(document.getElementById("root")).render(React.createElement(Chronometer));
console.log("Done");
