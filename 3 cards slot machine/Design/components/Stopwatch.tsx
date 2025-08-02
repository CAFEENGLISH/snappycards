import { useState, useEffect, useRef } from 'react';

interface StopwatchProps {
  isRunning: boolean;
  onReset?: () => void;
}

export function Stopwatch({ isRunning, onReset }: StopwatchProps) {
  const [time, setTime] = useState(0); // milliszekundumban
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const startTimeRef = useRef<number | null>(null);

  useEffect(() => {
    if (isRunning) {
      // Stopper indítása
      if (!startTimeRef.current) {
        startTimeRef.current = Date.now() - time;
      }
      
      intervalRef.current = setInterval(() => {
        if (startTimeRef.current) {
          setTime(Date.now() - startTimeRef.current);
        }
      }, 10); // 10ms pontosság
    } else {
      // Stopper megállítása
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      startTimeRef.current = null;
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isRunning, time]);

  // Reset funkció
  useEffect(() => {
    if (!isRunning && time === 0) {
      startTimeRef.current = null;
    }
  }, [isRunning, time]);

  // Ha reset van, nullázzuk az időt
  const handleReset = () => {
    setTime(0);
    startTimeRef.current = null;
    if (onReset) {
      onReset();
    }
  };

  // Időformázás: MM:SS.ms
  const formatTime = (milliseconds: number) => {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const ms = Math.floor((milliseconds % 1000) / 10);

    return `${minutes.toString().padStart(2, '0')}:${seconds
      .toString()
      .padStart(2, '0')}.${ms.toString().padStart(2, '0')}`;
  };

  // Mindig tartsa meg a helyet, de láthatatlan legyen, ha nincs aktív
  const shouldShow = isRunning || time > 0;

  return (
    <div className="flex items-center justify-center mt-6 mb-4 h-[60px]"> {/* Fix magasság */}
      <div 
        className={`bg-slate-900 text-white px-6 py-3 rounded-2xl shadow-lg border border-slate-700 transition-opacity duration-300 ${
          shouldShow ? 'opacity-100' : 'opacity-0'
        }`}
      >
        <div className="flex items-center gap-3">
          {/* Stopper ikon */}
          <div className={`w-3 h-3 rounded-full ${isRunning ? 'bg-red-500 animate-pulse' : 'bg-gray-500'}`}></div>
          
          {/* Idő kijelző */}
          <div className="font-mono text-xl tracking-wider">
            {formatTime(time)}
          </div>
          
          {/* Reset gomb (csak ha van idő és nem fut) */}
          {!isRunning && time > 0 && (
            <button
              onClick={handleReset}
              className="ml-2 text-xs bg-slate-700 hover:bg-slate-600 px-2 py-1 rounded transition-colors"
              title="Reset"
            >
              ⟲
            </button>
          )}
        </div>
      </div>
    </div>
  );
}