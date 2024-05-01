// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SaveARBTokenPair {
    address public owner;

    struct Feed {
        string[] symbols;
        address[] token1;
        address[] token2;
        address[] feedAddresses;
    }

    Feed private arbTestnetFeed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getARBFeed()
        public
        view
        returns (
            string[] memory,
            address[] memory,
            address[] memory,
            address[] memory
        )
    {
        return (
            arbTestnetFeed.symbols,
            arbTestnetFeed.token1,
            arbTestnetFeed.token2,
            arbTestnetFeed.feedAddresses
        );
    }

    function addTestnetFeed(
        Feed storage feed,
        string[] memory symbols,
        address[] memory feedAddresses,
        address[] memory token1,
        address[] memory token2
    ) internal {
        require(
            symbols.length == feedAddresses.length &&
                symbols.length == token1.length &&
                symbols.length == token2.length,
            "Arrays must have the same length"
        );
        for (uint i = 0; i < symbols.length; i++) {
            feed.symbols.push(symbols[i]);
            feed.feedAddresses.push(feedAddresses[i]);
            feed.token1.push(token1[i]);
            feed.token2.push(token2[i]);
        }
    }

    function addARBTesetnetFeed(
        string[] memory symbols,
        address[] memory feedAddresses,
        address[] memory token1,
        address[] memory token2
    ) public onlyOwner {
        addTestnetFeed(arbTestnetFeed, symbols, feedAddresses, token1, token2);
    }

    function clearFeed(Feed storage feed) internal {
        delete feed.symbols;
        delete feed.feedAddresses;
        delete feed.token1;
        delete feed.token2;
    }

    function removeARBFeed() public onlyOwner {
        clearFeed(arbTestnetFeed);
    }
}