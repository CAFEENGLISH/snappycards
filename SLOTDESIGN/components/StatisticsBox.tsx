interface StatisticsBoxProps {
  label: string;
  value: number;
  color: 'blue' | 'green' | 'purple' | 'yellow' | 'red' | 'orange';
}

export function StatisticsBox({ label, value, color }: StatisticsBoxProps) {
  const colorClasses = {
    blue: 'bg-blue-500 text-white',
    green: 'bg-green-500 text-white', 
    purple: 'bg-purple-500 text-white',
    yellow: 'bg-yellow-500 text-white',
    red: 'bg-red-500 text-white',
    orange: 'bg-orange-500 text-white'
  };

  return (
    <div className={`${colorClasses[color]} w-20 h-16 flex flex-col items-center justify-center rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105`}>
      <div className="text-center">
        <div className="text-lg font-bold leading-tight">{value} db</div>
        <div className="text-xs uppercase tracking-wide opacity-90 leading-tight">{label}</div>
      </div>
    </div>
  );
}