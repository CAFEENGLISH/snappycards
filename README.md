# SnappyCards 🧠⚡

> The world's first FlashCard system your brain will actually love

An AI-powered learning platform that uses neuroscience research to optimize flashcard learning through spaced repetition 2.0, neural priming effects, and reaction-time weighted learning.

## 🌟 Features

- **AI-Powered Personalization** - Learns how you learn and adapts accordingly
- **Spaced Repetition 2.0** - Next-generation spaced learning with individual cognitive patterns
- **Neural Priming Effect** - Cards appear in sequences that prime your brain
- **Reaction-Time Learning** - Measures knowledge depth based on response speed
- **Multimodal Content** - Learn words, sentences, images, videos, and animations
- **Hands-Free Mode** - Learn while driving with voice recognition
- **Modern UI** - Clean, Apple-inspired design with smooth animations

## 🚀 Tech Stack

- **Frontend**: Pure HTML, CSS, JavaScript
- **Backend**: Supabase (PostgreSQL)
- **Database**: Waitlist table with email validation
- **Hosting**: GitHub Pages ready
- **Fonts**: Inter (Google Fonts)

## 📊 Database Schema

### Waitlist Table
```sql
CREATE TABLE waitlist (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  confirmed BOOLEAN DEFAULT FALSE,
  confirmation_token VARCHAR(255) UNIQUE,
  confirmed_at TIMESTAMP WITH TIME ZONE
);
```

## 🛠️ Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/snappycards.git
   cd snappycards
   ```

2. **Supabase Configuration**
   - The project is already configured with Supabase
   - Project URL: `https://ycxqxdhaxehspypqbnpi.supabase.co`
   - Database includes waitlist table with RLS policies

3. **Run locally**
   - Simply open `index.html` in your browser
   - Or use a local server: `python -m http.server 8000`

## 🎨 Design Inspiration

- **Apple.com** - Clean, focused design
- **Notion.so** - Modern, tech-conscious interface  
- **Duolingo.com** - Playful yet intelligent learning-focused structure
- **Neurosity.co** - Scientific credibility with accessibility

## 📱 Responsive Design

- **Desktop**: Full two-column layouts with hero images
- **Mobile**: Single-column stack with optimized images
- **Tablet**: Adaptive grid system

## 🧪 Science Behind It

- **Spaced Repetition 2.0** - Individual cognitive pattern optimization
- **Neural Priming Effect** - 23% improvement in memorization efficiency
- **Reaction-Time Weighted Learning** - Knowledge depth measurement
- **Multimodal Encoding** - Stronger neural connections
- **Adaptive Chunking Strategy** - Cognitive load optimization
- **Goal-Oriented Feedback Loops** - Dopamine pathway alignment

## 📈 Analytics

The waitlist tracks:
- Email addresses (unique)
- Registration timestamps
- Confirmation status
- Sequential numbering (auto-increment ID)

## 🔒 Security

- Row Level Security (RLS) enabled
- Email validation on frontend and backend
- Unique constraint prevents duplicate emails
- Secure token generation for confirmation

## 🚀 Deployment

Ready for deployment on:
- GitHub Pages
- Netlify
- Vercel
- Any static hosting service

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

**Made with 🧠 and ⚡ for the future of learning** 