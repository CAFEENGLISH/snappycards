import { useState, useEffect } from "react";
import { StudyCard } from "./StudyCard";
import { StatisticsBox } from "./StatisticsBox";
import { Stopwatch } from "./Stopwatch";
import { FeedbackType } from "./types";

interface CardSet {
  id: string;
  cards: Array<{
    title: string;
    englishTitle: string;
    imageUrl: string;
    imageAlt: string;
  }>;
}

export function SlotMachine() {
  const [spinningCard, setSpinningCard] = useState<
    number | null
  >(null);
  const [flippedCards, setFlippedCards] = useState<Set<number>>(
    new Set(),
  );
  const [feedback, setFeedback] = useState<
    Record<number, FeedbackType>
  >({});
  const [currentCardSetIndex, setCurrentCardSetIndex] =
    useState(0);
  const [isStopwatchRunning, setIsStopwatchRunning] =
    useState(false);

  // Statisztikák nyomon követése
  const [statistics, setStatistics] = useState({
    tudom: 0,
    bizonytalan: 0,
    tanulandó: 0,
    totalViewed: 0,
  });

  const cardSets: CardSet[] = [
    {
      id: "set1",
      cards: [
        {
          title: "Alma",
          englishTitle: "Apple",
          imageUrl:
            "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=500&h=400&fit=crop",
          imageAlt: "Piros alma",
        },
        {
          title: "Csónak",
          englishTitle: "Boat",
          imageUrl:
            "https://images.unsplash.com/photo-1504214208698-ea1916a2195a?w=500&h=400&fit=crop",
          imageAlt: "Fehér-szürke fa csónak",
        },
        {
          title: "Ház",
          englishTitle: "House",
          imageUrl:
            "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=500&h=400&fit=crop",
          imageAlt: "Szép ház",
        },
      ],
    },
    {
      id: "set2",
      cards: [
        {
          title: "Vitorlás",
          englishTitle: "Sailboat",
          imageUrl:
            "https://images.unsplash.com/photo-1527511949914-1a69c0c60da3?w=500&h=400&fit=crop",
          imageAlt: "Vitorlás hajó",
        },
        {
          title: "Tengerpart",
          englishTitle: "Beach",
          imageUrl:
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop",
          imageAlt: "Szép tengerpart",
        },
        {
          title: "Pálmafa",
          englishTitle: "Palm tree",
          imageUrl:
            "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop",
          imageAlt: "Trópusi pálmafa",
        },
      ],
    },
  ];

  const currentCards =
    cardSets[currentCardSetIndex]?.cards || [];

  // Ellenőrizzük, hogy minden kártya kapott-e visszajelzést
  const allCardsHaveFeedback = currentCards.every(
    (_, index) =>
      feedback[index] !== undefined && feedback[index] !== null,
  );

  // Stopper megállítása, ha minden kártya értékelve lett
  useEffect(() => {
    if (allCardsHaveFeedback && flippedCards.size > 0) {
      setIsStopwatchRunning(false);
    }
  }, [allCardsHaveFeedback, flippedCards.size]);

  // Dinamikus statisztikai értékek
  const totalPossibleCards = cardSets.reduce(
    (sum, set) => sum + set.cards.length,
    0,
  );
  const viewedCards = statistics.totalViewed;
  const remainingCards = Math.max(
    0,
    totalPossibleCards - statistics.tudom,
  );
  const totalCards = totalPossibleCards;

  useEffect(() => {
    console.log("useEffect triggered:", {
      allCardsHaveFeedback,
      currentCardsLength: currentCards.length,
      currentCardSetIndex,
      maxSets: cardSets.length,
    });

    if (
      allCardsHaveFeedback &&
      currentCards.length > 0 &&
      currentCardSetIndex < cardSets.length - 1
    ) {
      console.log("Starting 2 second timer for new cards...");

      // 2 másodperc várakozás után új kártyák betöltése
      const timer = setTimeout(() => {
        console.log("Loading new card set...");
        setCurrentCardSetIndex((prev) => prev + 1);
        setFlippedCards(new Set());
        setFeedback({});
        setSpinningCard(null);
        setIsStopwatchRunning(false); // Stopper megállítása új kártyák betöltésekor
        // Statisztikák megmaradnak!
      }, 2000);

      return () => {
        console.log("Clearing timer");
        clearTimeout(timer);
      };
    }
  }, [
    allCardsHaveFeedback,
    currentCardSetIndex,
    cardSets.length,
    currentCards.length,
  ]);

  const handleCardClick = (index: number) => {
    if (spinningCard !== null) return;

    setSpinningCard(index);

    setTimeout(() => {
      setSpinningCard(null);
      setFlippedCards((prev) => {
        const newSet = new Set(prev);
        if (newSet.has(index)) {
          newSet.delete(index);
        } else {
          newSet.add(index);
          // Ha ez az első megfordított kártya, várunk még 1 másodpercet a stopper indítása előtt
          if (newSet.size === 1) {
            setTimeout(() => {
              setIsStopwatchRunning(true);
            }, 1000); // +1 másodperc várakozás a pörgés vége után
          }
        }
        return newSet;
      });
    }, 1500);
  };

  const handleFeedback = (
    cardIndex: number,
    feedbackType: FeedbackType,
  ) => {
    console.log(
      "🎯 Feedback received for card",
      cardIndex,
      ":",
      feedbackType,
    );

    setFeedback((prev) => {
      const oldFeedback = prev[cardIndex];
      const newFeedback = {
        ...prev,
        [cardIndex]: feedbackType,
      };

      // Statisztikák frissítése
      setStatistics((prevStats) => {
        let newStats = { ...prevStats };

        // Ha volt már feedback erre a kártyára, csökkentjük a régit
        if (oldFeedback) {
          newStats[oldFeedback] = Math.max(
            0,
            newStats[oldFeedback] - 1,
          );
        } else {
          // Ha új feedback, növeljük a total viewed-ot
          newStats.totalViewed += 1;
        }

        // Növeljük az új feedback típust
        newStats[feedbackType] += 1;

        console.log("📊 Updated statistics:", newStats);
        return newStats;
      });

      console.log("📊 New feedback state:", newFeedback);
      console.log(
        "🔢 Current cards length:",
        currentCards.length,
      );

      // Ellenőrizzük rögtön, hogy minden kártya kapott-e feedbacket
      const hasAllFeedback = currentCards.every(
        (_, index) =>
          newFeedback[index] !== undefined &&
          newFeedback[index] !== null,
      );
      console.log(
        "✨ All cards have feedback:",
        hasAllFeedback,
      );

      return newFeedback;
    });
  };

  const handleFeedbackClick = () => {
    // Stopper megállítása bármely feedback gomb megnyomásakor
    setIsStopwatchRunning(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 flex items-center justify-center p-8">
      <div className="max-w-6xl w-full">
        {/* Fejléc */}
        <div className="text-center mb-12">
          <div className="mb-4">
            {/* Hero Title - Glassmorphism Bubble Design */}
            <div className="relative inline-block hero-glass-container">
              <div className="relative bg-white/10 backdrop-blur-xl rounded-3xl p-8 border border-white/20 shadow-2xl hero-glass-card">
                <h1 className="text-6xl font-extrabold mb-2 tracking-tight relative z-10">
                  <span className="hero-gradient-text bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                    Snappy
                  </span>
                  <span className="ml-3 text-slate-700">
                    Cards
                  </span>
                </h1>

                {/* Floating bubbles */}
                <div className="absolute -top-4 -left-6 w-12 h-12 hero-bubble-1"></div>
                <div className="absolute -top-8 -right-4 w-8 h-8 hero-bubble-2"></div>
                <div className="absolute -bottom-6 left-1/4 w-10 h-10 hero-bubble-3"></div>
                <div className="absolute -bottom-4 -right-8 w-6 h-6 hero-bubble-4"></div>
              </div>

              {/* Background glow */}
              <div className="absolute inset-0 bg-gradient-to-r from-indigo-400/20 via-purple-400/20 to-pink-400/20 blur-3xl scale-110 -z-10"></div>
            </div>
          </div>
          <div className="h-px bg-gradient-to-r from-transparent via-slate-300 to-transparent mx-auto w-96 mt-6"></div>

          {/* Stopper - mindig jelen van, fix placeholder */}
          <Stopwatch
            isRunning={
              isStopwatchRunning && flippedCards.size > 0
            }
            onReset={() => setIsStopwatchRunning(false)}
          />
        </div>

        {/* Kártyák sor */}
        <div className="flex gap-8 justify-center items-center flex-wrap">
          {currentCards.map((card, index) => (
            <StudyCard
              key={`${currentCardSetIndex}-${index}`}
              title={card.title}
              englishTitle={card.englishTitle}
              imageUrl={card.imageUrl}
              imageAlt={card.imageAlt}
              isSpinning={spinningCard === index}
              isFlipped={flippedCards.has(index)}
              onClick={() => handleCardClick(index)}
              feedback={feedback[index]}
              onFeedback={(feedbackType) =>
                handleFeedback(index, feedbackType)
              }
              onFeedbackClick={handleFeedbackClick}
            />
          ))}
        </div>

        {/* Statisztikák - 3+3 csoportban */}
        <div className="mt-12">
          <div className="flex justify-center items-center gap-12 flex-wrap">
            {/* Bal csoport - Feedback típusok */}
            <div className="flex gap-3">
              <StatisticsBox
                label="Tudom"
                value={statistics.tudom}
                color="green"
              />
              <StatisticsBox
                label="Bizonytalan"
                value={statistics.bizonytalan}
                color="yellow"
              />
              <StatisticsBox
                label="Tanulandó"
                value={statistics.tanulandó}
                color="red"
              />
            </div>

            {/* Jobb csoport - Általános statisztikák */}
            <div className="flex gap-3">
              <StatisticsBox
                label="Megnézve"
                value={viewedCards}
                color="orange"
              />
              <StatisticsBox
                label="Hátra van"
                value={remainingCards}
                color="blue"
              />
              <StatisticsBox
                label="Összesen"
                value={totalCards}
                color="purple"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}