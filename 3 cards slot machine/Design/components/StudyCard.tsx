import { Card } from "./ui/card";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { motion } from "motion/react";
import { FeedbackType } from "./types";
import { FeedbackButtons } from "./FeedbackButtons";

interface StudyCardProps {
  title: string;
  englishTitle: string;
  imageUrl: string;
  imageAlt: string;
  isSpinning: boolean;
  isFlipped: boolean;
  onClick: () => void;
  feedback?: FeedbackType;
  onFeedback?: (feedbackType: FeedbackType) => void;
  onFeedbackClick?: () => void; // Új callback a stopper megállításához
}

export function StudyCard({ 
  title, 
  englishTitle, 
  imageUrl, 
  imageAlt, 
  isSpinning, 
  isFlipped, 
  onClick, 
  feedback, 
  onFeedback,
  onFeedbackClick
}: StudyCardProps) {

  const handleCardClick = (e: React.MouseEvent) => {
    // Ne kattintson a kártyára, ha a feedback gombok területén történik
    if ((e.target as HTMLElement).closest('.snappy-feedback-container')) {
      return;
    }
    onClick();
  };

  return (
    <div className="perspective-1000 cursor-pointer" onClick={handleCardClick}>
      <motion.div
        animate={
          isSpinning 
            ? { rotateX: 1080 } // 3 teljes fordulat
            : isFlipped 
              ? { rotateX: 180 }
              : { rotateX: 0 }
        }
        transition={
          isSpinning
            ? {
                duration: 1.5,
                ease: [0.55, 0.055, 0.675, 0.19] // Gyors indítás, majd fokozatos lassulás
              }
            : {
                duration: 0.6,
                ease: [0.25, 0.46, 0.45, 0.94]
              }
        }
        style={{ 
          transformStyle: "preserve-3d",
          perspective: "1000px",
          width: '316.8px', 
          height: '422.4px'
        }}
        className="relative"
      >
        {/* Előlap - Magyar */}
        <Card className="absolute inset-0 bg-white border border-slate-200 shadow-lg hover:shadow-xl transform transition-all duration-300 hover:scale-[1.02] overflow-hidden group backface-hidden">
          <div className="h-full flex flex-col">
            {/* Hero kép - 50% */}
            <div className="h-1/2 overflow-hidden relative">
              <ImageWithFallback 
                src={imageUrl}
                alt={imageAlt}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/10 to-transparent"></div>
            </div>
            
            {/* Elválasztó */}
            <div className="h-0.5 bg-slate-300"></div>
            
            {/* Szöveg rész - 50% */}
            <div className="h-1/2 p-6 bg-slate-50 flex items-center justify-center">
              <h3 className="text-slate-700 text-2xl text-center tracking-tight">
                {title}
              </h3>
            </div>
          </div>
        </Card>

        {/* Hátlap - Angol */}
        <Card 
          className="absolute inset-0 bg-white border border-indigo-300 shadow-lg overflow-hidden group backface-hidden"
          style={{ transform: 'rotateX(180deg)' }}
        >
          <div className="h-full flex flex-col">
            {/* Hero kép - 50% */}
            <div className="h-1/2 overflow-hidden relative">
              <ImageWithFallback 
                src={imageUrl}
                alt={imageAlt}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-indigo-500/30 to-transparent"></div>
              <div className="absolute top-4 right-4 bg-indigo-600 text-white px-2 py-1 rounded-full text-xs">
                EN
              </div>
            </div>
            
            {/* Elválasztó */}
            <div className="h-0.5 bg-indigo-300"></div>
            
            {/* Angol szöveg rész - 35% */}
            <div className="flex-1 p-6 bg-gradient-to-br from-indigo-50 to-blue-50 flex items-center justify-center">
              <h3 className="text-indigo-700 text-2xl text-center tracking-tight">
                {englishTitle}
              </h3>
            </div>

            {/* Értékelési sáv - 15% */}
            <div className="p-3 bg-white border-t border-indigo-200">
              {isSpinning ? (
                <div className="text-center text-indigo-500 text-sm">🪙 Pörgés...</div>
              ) : (
                <FeedbackButtons 
                  feedback={feedback} 
                  onFeedback={onFeedback}
                  onFeedbackClick={onFeedbackClick}
                />
              )}
            </div>
          </div>
        </Card>
      </motion.div>
    </div>
  );
}