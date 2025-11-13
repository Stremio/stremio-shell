import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Window 2.2

ApplicationWindow {
    id: demoWindow
    visible: true
    width: 1200
    height: 800
    title: "Stremio Search & Filter Demo"
    color: "#0c0b11"
    
    FilteredContentView {
        id: contentView
        anchors.fill: parent
        
        Component.onCompleted: {
            // Sample content data with comprehensive metadata
            var sampleContent = [
                {
                    title: "Blade Runner 2049",
                    year: 2017,
                    rating: 8.0,
                    poster: "",
                    genres: ["sci-fi", "thriller"],
                    moods: ["existential", "dark"],
                    cinematography: ["slow burn", "neo-noir"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "A young blade runner discovers a secret that could plunge society into chaos."
                },
                {
                    title: "Parasite",
                    year: 2019,
                    rating: 8.6,
                    poster: "",
                    genres: ["thriller", "drama"],
                    moods: ["dark", "intense"],
                    cinematography: ["minimalist"],
                    countries: ["South Korea"],
                    awards: ["Oscar Winner", "Cannes"],
                    description: "A poor family schemes to become employed by a wealthy family."
                },
                {
                    title: "The Grand Budapest Hotel",
                    year: 2014,
                    rating: 8.1,
                    poster: "",
                    genres: ["comedy", "drama"],
                    moods: ["light-hearted", "uplifting"],
                    cinematography: ["epic", "minimalist"],
                    countries: ["USA", "UK"],
                    awards: ["Oscar Winner", "BAFTA"],
                    description: "The adventures of Gustave H, a legendary concierge."
                },
                {
                    title: "Mad Max: Fury Road",
                    year: 2015,
                    rating: 8.1,
                    poster: "",
                    genres: ["action", "thriller"],
                    moods: ["intense"],
                    cinematography: ["fast-paced", "epic"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "In a post-apocalyptic wasteland, Max teams up with Furiosa."
                },
                {
                    title: "Her",
                    year: 2013,
                    rating: 8.0,
                    poster: "",
                    genres: ["sci-fi", "romance", "drama"],
                    moods: ["existential", "intimate"],
                    cinematography: ["slow burn", "intimate"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "A man develops a relationship with an AI operating system."
                },
                {
                    title: "Moonlight",
                    year: 2016,
                    rating: 7.4,
                    poster: "",
                    genres: ["drama"],
                    moods: ["intimate", "dark"],
                    cinematography: ["intimate", "minimalist"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "A chronicle of the childhood, adolescence and burgeoning adulthood of a young black man."
                },
                {
                    title: "The Handmaiden",
                    year: 2016,
                    rating: 8.1,
                    poster: "",
                    genres: ["thriller", "romance"],
                    moods: ["mysterious", "intense"],
                    cinematography: ["neo-noir"],
                    countries: ["South Korea"],
                    awards: ["Cannes"],
                    description: "A woman is hired as a handmaiden to a Japanese heiress."
                },
                {
                    title: "Call Me by Your Name",
                    year: 2017,
                    rating: 7.9,
                    poster: "",
                    genres: ["romance", "drama"],
                    moods: ["intimate", "uplifting"],
                    cinematography: ["slow burn", "intimate"],
                    countries: ["Italy", "France"],
                    awards: ["Oscar Winner"],
                    description: "In 1980s Italy, romance blossoms between a seventeen-year-old student and an older man."
                },
                {
                    title: "Arrival",
                    year: 2016,
                    rating: 7.9,
                    poster: "",
                    genres: ["sci-fi", "drama"],
                    moods: ["existential", "mysterious"],
                    cinematography: ["slow burn", "minimalist"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "A linguist works with the military to communicate with alien lifeforms."
                },
                {
                    title: "The Shape of Water",
                    year: 2017,
                    rating: 7.3,
                    poster: "",
                    genres: ["romance", "drama", "thriller"],
                    moods: ["mysterious", "uplifting"],
                    cinematography: ["neo-noir", "intimate"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "At a top secret research facility, a lonely janitor forms a unique relationship with an amphibious creature."
                },
                {
                    title: "Whiplash",
                    year: 2014,
                    rating: 8.5,
                    poster: "",
                    genres: ["drama"],
                    moods: ["intense"],
                    cinematography: ["fast-paced", "intimate"],
                    countries: ["USA"],
                    awards: ["Oscar Winner"],
                    description: "A promising young drummer enrolls at a cut-throat music conservatory."
                },
                {
                    title: "Roma",
                    year: 2018,
                    rating: 7.7,
                    poster: "",
                    genres: ["drama"],
                    moods: ["intimate"],
                    cinematography: ["slow burn", "minimalist"],
                    countries: ["Mexico"],
                    awards: ["Oscar Winner"],
                    description: "A year in the life of a middle-class family's maid in Mexico City in the early 1970s."
                }
            ];
            
            contentView.setContent(sampleContent);
        }
    }
}