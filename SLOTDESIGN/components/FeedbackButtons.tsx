import { FeedbackType } from "./types";

interface FeedbackButtonsProps {
  feedback?: FeedbackType;
  onFeedback?: (feedbackType: FeedbackType) => void;
  onFeedbackClick?: () => void; // Új callback a stopper megállításához
}

export function FeedbackButtons({ feedback, onFeedback, onFeedbackClick }: FeedbackButtonsProps) {
  const handleFeedbackClick = (e: React.MouseEvent, feedbackType: FeedbackType) => {
    e.preventDefault();
    e.stopPropagation();
    e.nativeEvent.stopImmediatePropagation();
    
    console.log('🔥 Feedback button clicked:', feedbackType);
    
    // Stopper megállítása azonnal
    if (onFeedbackClick) {
      onFeedbackClick();
    }
    
    if (onFeedback) {
      console.log('✅ Calling onFeedback with:', feedbackType);
      onFeedback(feedbackType);
    } else {
      console.log('❌ onFeedback is not available');
    }
  };

  const getButtonClass = (type: FeedbackType) => {
    const baseClass = "snappy-btn-base";
    const isSelected = feedback === type;
    
    // Minden gomb eleve színes, kiválasztott állapotban plusz border/shadow
    switch (type) {
      case "tudom":
        return `${baseClass} snappy-btn-green ${isSelected ? 'snappy-btn-selected' : ''}`;
      case "bizonytalan":
        return `${baseClass} snappy-btn-yellow ${isSelected ? 'snappy-btn-selected' : ''}`;
      case "tanulandó":
        return `${baseClass} snappy-btn-red ${isSelected ? 'snappy-btn-selected' : ''}`;
      default:
        return `${baseClass} snappy-btn-default`;
    }
  };

  return (
    <div className="snappy-feedback-container" onClick={(e) => e.stopPropagation()}>
      <button
        className={getButtonClass("tudom")}
        onClick={(e) => handleFeedbackClick(e, "tudom")}
        type="button"
        data-feedback="tudom"
      >
        Tudom
      </button>
      
      <button
        className={getButtonClass("bizonytalan")}
        onClick={(e) => handleFeedbackClick(e, "bizonytalan")}
        type="button"
        data-feedback="bizonytalan"
      >
        Bizonytalan
      </button>
      
      <button
        className={getButtonClass("tanulandó")}
        onClick={(e) => handleFeedbackClick(e, "tanulandó")}
        type="button"
        data-feedback="tanulandó"
      >
        Tanulandó
      </button>
    </div>
  );
}