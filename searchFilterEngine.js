// Search and Filter Engine for Stremio
// Handles multi-tag filtering, search, and content matching

class SearchFilterEngine {
    constructor() {
        this.filters = {
            searchText: "",
            tags: [],
            yearRange: { min: 1900, max: 2024 },
            ratingRange: { min: 0.0, max: 10.0 }
        };
        
        this.content = [];
        this.filteredContent = [];
        this.onFilterChange = null;
    }
    
    // Set the content to be filtered
    setContent(content) {
        this.content = content;
        this.applyFilters();
    }
    
    // Update filters and trigger filtering
    updateFilters(newFilters) {
        this.filters = { ...this.filters, ...newFilters };
        this.applyFilters();
    }
    
    // Apply all active filters to content
    applyFilters() {
        let filtered = [...this.content];
        
        // Apply search text filter
        if (this.filters.searchText && this.filters.searchText.trim() !== "") {
            filtered = this.filterBySearchText(filtered, this.filters.searchText);
        }
        
        // Apply tag filters
        if (this.filters.tags && this.filters.tags.length > 0) {
            filtered = this.filterByTags(filtered, this.filters.tags);
        }
        
        // Apply year range filter
        if (this.filters.yearRange) {
            filtered = this.filterByYearRange(filtered, this.filters.yearRange);
        }
        
        // Apply rating range filter
        if (this.filters.ratingRange) {
            filtered = this.filterByRatingRange(filtered, this.filters.ratingRange);
        }
        
        this.filteredContent = filtered;
        
        if (this.onFilterChange) {
            this.onFilterChange(this.filteredContent, this.filters);
        }
        
        return this.filteredContent;
    }
    
    // Filter by search text (title, description, actors, directors)
    filterBySearchText(content, searchText) {
        const searchTerms = searchText.toLowerCase().split(' ').filter(term => term.length > 0);
        
        return content.filter(item => {
            const searchableText = [
                item.title || "",
                item.description || "",
                item.plot || "",
                ...(item.actors || []),
                ...(item.directors || []),
                ...(item.genres || []),
                item.year ? item.year.toString() : ""
            ].join(' ').toLowerCase();
            
            return searchTerms.every(term => searchableText.includes(term));
        });
    }
    
    // Filter by multiple tags with AND logic within categories, OR between categories
    filterByTags(content, tags) {
        if (!tags || tags.length === 0) return content;
        
        // Group tags by category
        const tagsByCategory = {};
        tags.forEach(tagObj => {
            if (!tagsByCategory[tagObj.category]) {
                tagsByCategory[tagObj.category] = [];
            }
            tagsByCategory[tagObj.category].push(tagObj.tag.toLowerCase());
        });
        
        return content.filter(item => {
            // All categories must match (AND between categories)
            return Object.keys(tagsByCategory).every(category => {
                const categoryTags = tagsByCategory[category];
                return this.matchesCategory(item, category, categoryTags);
            });
        });
    }
    
    // Check if item matches tags in a specific category
    matchesCategory(item, category, tags) {
        switch (category) {
            case 'genre':
                return this.matchesAnyTag(item.genres || [], tags);
            
            case 'mood':
                return this.matchesAnyTag(item.moods || [], tags);
            
            case 'cinematography':
                return this.matchesAnyTag(item.cinematography || [], tags);
            
            case 'country':
                return this.matchesAnyTag(item.countries || [], tags);
            
            case 'awards':
                return this.matchesAnyTag(item.awards || [], tags);
            
            default:
                return true;
        }
    }
    
    // Check if any of the item's tags match the filter tags (OR within category)
    matchesAnyTag(itemTags, filterTags) {
        if (!itemTags || itemTags.length === 0) return false;
        
        const itemTagsLower = itemTags.map(tag => tag.toLowerCase());
        return filterTags.some(filterTag => 
            itemTagsLower.some(itemTag => itemTag.includes(filterTag))
        );
    }
    
    // Filter by year range
    filterByYearRange(content, yearRange) {
        return content.filter(item => {
            const year = parseInt(item.year) || 0;
            return year >= yearRange.min && year <= yearRange.max;
        });
    }
    
    // Filter by rating range
    filterByRatingRange(content, ratingRange) {
        return content.filter(item => {
            const rating = parseFloat(item.rating) || 0;
            return rating >= ratingRange.min && rating <= ratingRange.max;
        });
    }
    
    // Get current filter summary
    getFilterSummary() {
        const summary = {
            totalItems: this.content.length,
            filteredItems: this.filteredContent.length,
            activeFilters: 0,
            filterDetails: {}
        };
        
        if (this.filters.searchText && this.filters.searchText.trim() !== "") {
            summary.activeFilters++;
            summary.filterDetails.search = this.filters.searchText;
        }
        
        if (this.filters.tags && this.filters.tags.length > 0) {
            summary.activeFilters++;
            summary.filterDetails.tags = this.filters.tags.length;
        }
        
        if (this.filters.yearRange && 
            (this.filters.yearRange.min > 1900 || this.filters.yearRange.max < 2024)) {
            summary.activeFilters++;
            summary.filterDetails.yearRange = this.filters.yearRange;
        }
        
        if (this.filters.ratingRange && 
            (this.filters.ratingRange.min > 0 || this.filters.ratingRange.max < 10)) {
            summary.activeFilters++;
            summary.filterDetails.ratingRange = this.filters.ratingRange;
        }
        
        return summary;
    }
    
    // Clear all filters
    clearAllFilters() {
        this.filters = {
            searchText: "",
            tags: [],
            yearRange: { min: 1900, max: 2024 },
            ratingRange: { min: 0.0, max: 10.0 }
        };
        this.applyFilters();
    }
    
    // Set callback for filter changes
    setOnFilterChange(callback) {
        this.onFilterChange = callback;
    }
    
    // Get suggested tags based on current content
    getSuggestedTags() {
        const suggestions = {
            genres: new Set(),
            moods: new Set(),
            cinematography: new Set(),
            countries: new Set(),
            awards: new Set()
        };
        
        this.content.forEach(item => {
            (item.genres || []).forEach(tag => suggestions.genres.add(tag));
            (item.moods || []).forEach(tag => suggestions.moods.add(tag));
            (item.cinematography || []).forEach(tag => suggestions.cinematography.add(tag));
            (item.countries || []).forEach(tag => suggestions.countries.add(tag));
            (item.awards || []).forEach(tag => suggestions.awards.add(tag));
        });
        
        return {
            genres: Array.from(suggestions.genres).sort(),
            moods: Array.from(suggestions.moods).sort(),
            cinematography: Array.from(suggestions.cinematography).sort(),
            countries: Array.from(suggestions.countries).sort(),
            awards: Array.from(suggestions.awards).sort()
        };
    }
}

// Export for use in QML
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SearchFilterEngine;
} else if (typeof window !== 'undefined') {
    window.SearchFilterEngine = SearchFilterEngine;
}