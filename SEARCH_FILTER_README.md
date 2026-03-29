# Stremio Search & Tag-Based Filter System

A comprehensive search and filtering system for Stremio that supports multi-tag search, tooltips, and advanced filtering by years, ratings, and various content attributes.

## Features

### 🔍 Multi-Tag Search
- **Genre filtering**: sci-fi, drama, comedy, action, thriller, horror, romance, documentary
- **Mood filtering**: existential, uplifting, dark, mysterious, intense, light-hearted
- **Cinematography style**: slow burn, fast-paced, neo-noir, minimalist, epic, intimate
- **Country filtering**: USA, UK, France, Japan, South Korea, Germany, Italy, Spain
- **Awards filtering**: Oscar Winner, Emmy Winner, Golden Globe, Cannes, Sundance, BAFTA

### 📅 Year Range Filtering
- Dual-handle slider for selecting year ranges (1900-2024)
- Smooth dragging interaction
- Real-time filtering as you adjust the range

### ⭐ Rating Range Filtering
- IMDb rating filter with decimal precision (0.0-10.0)
- Visual feedback with color-coded rating badges
- Customizable step size and decimal places

### 💡 Interactive Tooltips
- Hover over tags to see detailed explanations
- Examples:
  - "slow burn": Films with deliberate pacing that build tension gradually
  - "neo-noir": Modern films with classic noir elements: dark themes, moral ambiguity
  - "existential": Explores questions about existence, meaning, and human condition

### 🎯 Advanced Search Logic
- **Text search**: Searches across title, description, actors, directors, genres
- **Multi-category filtering**: AND logic between categories, OR within categories
- **Real-time filtering**: Instant results as you type or select tags
- **Filter summary**: Shows active filters and result counts

## Components

### Core Components
1. **SearchFilter.qml** - Main filter panel with all controls
2. **TagCategory.qml** - Groups related tags by category
3. **TagButton.qml** - Individual tag buttons with tooltips
4. **RangeFilter.qml** - Dual-handle range slider component
5. **FilteredContentView.qml** - Main view combining filters and content
6. **ContentCard.qml** - Individual content display cards

### JavaScript Engine
- **searchFilterEngine.js** - Core filtering logic and algorithms

## Usage

### Basic Integration

```qml
import QtQuick 2.7
import QtQuick.Controls 2.0

FilteredContentView {
    id: contentView
    anchors.fill: parent
    
    Component.onCompleted: {
        // Set your content data
        var content = [
            {
                title: "Blade Runner 2049",
                year: 2017,
                rating: 8.0,
                genres: ["sci-fi", "thriller"],
                moods: ["existential", "dark"],
                cinematography: ["slow burn", "neo-noir"],
                countries: ["USA"],
                awards: ["Oscar Winner"]
            }
            // ... more content
        ];
        
        contentView.setContent(content);
    }
}
```

### Content Data Format

Each content item should include the following properties:

```javascript
{
    title: "Movie Title",           // Required
    year: 2023,                    // Required for year filtering
    rating: 8.5,                   // Required for rating filtering
    poster: "image_url",           // Optional poster image
    description: "Plot summary",    // Optional, used in text search
    genres: ["sci-fi", "drama"],   // Array of genre tags
    moods: ["dark", "intense"],    // Array of mood tags
    cinematography: ["neo-noir"],   // Array of cinematography tags
    countries: ["USA", "UK"],      // Array of country tags
    awards: ["Oscar Winner"],      // Array of award tags
    actors: ["Actor Name"],        // Optional, used in text search
    directors: ["Director Name"]   // Optional, used in text search
}
```

### Customizing Tags

You can customize available tags by modifying the `availableTags` property in SearchFilter.qml:

```qml
property var availableTags: {
    "genres": ["your", "custom", "genres"],
    "moods": ["your", "custom", "moods"],
    // ... other categories
}
```

### Adding New Tooltips

Add tooltip explanations in TagButton.qml's `getTooltipText` function:

```javascript
function getTooltipText(tag) {
    var tooltips = {
        "your-tag": "Your tooltip explanation",
        // ... existing tooltips
    }
    return tooltips[tag] || ""
}
```

## Demo Application

Run the demo to see the system in action:

```bash
qmake SearchFilterDemo.qml
make
./SearchFilterDemo
```

The demo includes sample movie data with comprehensive metadata to showcase all filtering features.

## Integration with Stremio

### Web UI Integration
Since Stremio uses a web-based UI loaded via WebEngineView, you can:

1. **QML Overlay**: Add the filter system as a QML overlay on top of the web view
2. **Web Integration**: Export the filtering logic to JavaScript and integrate with the web UI
3. **Hybrid Approach**: Use QML for the filter panel and communicate with the web UI via WebChannel

### Example Web Integration

```javascript
// In your web UI
import { SearchFilterEngine } from './searchFilterEngine.js';

const filterEngine = new SearchFilterEngine();
filterEngine.setContent(yourContentArray);
filterEngine.setOnFilterChange((filtered, filters) => {
    updateContentDisplay(filtered);
});
```

## Performance Considerations

- **Efficient Filtering**: The engine uses optimized algorithms for large content libraries
- **Debounced Search**: Text search is debounced to prevent excessive filtering
- **Lazy Loading**: Content cards support lazy loading for better performance
- **Memory Management**: Proper cleanup of filter states and event listeners

## Browser Compatibility

The JavaScript engine is compatible with:
- Modern browsers (ES6+)
- Qt WebEngine
- Node.js environments

## Future Enhancements

- **Saved Filters**: Allow users to save and recall filter presets
- **Smart Suggestions**: AI-powered tag suggestions based on viewing history
- **Advanced Search**: Boolean operators and complex query syntax
- **Performance Analytics**: Track filter usage and optimize accordingly
- **Accessibility**: Full keyboard navigation and screen reader support

## Contributing

When adding new features:
1. Follow the existing component structure
2. Add comprehensive tooltips for new tags
3. Update the demo with relevant examples
4. Ensure cross-platform compatibility
5. Add unit tests for new filtering logic

## License

This search and filter system is part of the Stremio project and follows the same licensing terms.