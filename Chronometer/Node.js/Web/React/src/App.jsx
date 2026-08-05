import { useState, useRef, useCallback } from 'react'

function formatTime(ms) {
  const totalMs = Math.floor(ms)
  const hours = Math.floor(totalMs / 3600000)
  const minutes = Math.floor((totalMs % 3600000) / 60000)
  const seconds = Math.floor((totalMs % 60000) / 1000)
  const millis = totalMs % 1000
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(millis).padStart(3, '0')}`
}

function App() {
  const [time, setTime] = useState(0)
  const [running, setRunning] = useState(false)
  const [laps, setLaps] = useState([])
  const intervalRef = useRef(null)
  const startTimeRef = useRef(0)

  const start = useCallback(() => {
    if (running) return
    startTimeRef.current = Date.now() - time
    intervalRef.current = setInterval(() => {
      setTime(Date.now() - startTimeRef.current)
    }, 10)
    setRunning(true)
  }, [running, time])

  const stop = useCallback(() => {
    if (!running) return
    clearInterval(intervalRef.current)
    setRunning(false)
  }, [running])

  const reset = useCallback(() => {
    clearInterval(intervalRef.current)
    setRunning(false)
    setTime(0)
    setLaps([])
  }, [])

  const lap = useCallback(() => {
    if (!running) return
    setLaps((prev) => [formatTime(time), ...prev])
  }, [running, time])

  return (
    <div className="chronometer">
      <h1>Chronometer</h1>
      <div className="display">{formatTime(time)}</div>
      <div className="controls">
        {!running ? (
          <button className="btn start" onClick={start}>Start</button>
        ) : (
          <button className="btn stop" onClick={stop}>Stop</button>
        )}
        <button className="btn reset" onClick={reset}>Reset</button>
        <button className="btn lap" onClick={lap} disabled={!running}>Lap</button>
      </div>
      {laps.length > 0 && (
        <div className="laps">
          <h2>Laps</h2>
          <ul>
            {laps.map((l, i) => (
              <li key={i}>Lap {laps.length - i}: {l}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}

export default App
