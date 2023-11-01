pragma solidity ^0.8.0;

// Deployed with the Atlas IDE
// https://app.atlaszk.com


contract LocationContract {
    struct Location {
        string name;
        int256 latitude;
        int256 longitude;
    }

    Location public location;

    function setLocation(string memory _name, int256 _latitude, int256 _longitude) public {
        location = Location(_name, _latitude, _longitude);
    }
}