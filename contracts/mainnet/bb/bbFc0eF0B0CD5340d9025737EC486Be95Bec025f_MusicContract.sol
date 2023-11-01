// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract MusicContract {
    struct Song {
        string title;
        string artist;
        uint duration; // duration in seconds
    }

    Song[] public songs;

    function addSong(string memory _title, string memory _artist, uint _duration) public {
        songs.push(Song(_title, _artist, _duration));
    }

    function getSong(uint _index) public view returns (string memory, string memory, uint) {
        Song memory song = songs[_index];
        return (song.title, song.artist, song.duration);
    }
}