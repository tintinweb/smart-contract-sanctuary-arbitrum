// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPokerEvaluator {
    // return the point of a hand
    function evaluate(uint256[] calldata cards) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IPokerEvaluator.sol";
import "./pokersolver/Evaluator7.sol";

contract PokerEvaluator is IPokerEvaluator {
    address public evaluator;
    constructor(address evaluator_) {
        require(evaluator_ != address(0), "invalid evaluator address");
        evaluator = evaluator_;
    }
    /** we need to map the card value to the evaluator
     * in frontend:
        export enum Suit {
            Spades = "s",
            Hearts = "h",
            Diamonds = "d",
            Clubs = "c"
        };
        export enum Rank {
            Two = "2",
            Three = "3",
            Four = "4",
            Five = "5",
            Six = "6",
            Seven = "7",
            Eight = "8",
            Nine = "9",
            Ten = "T",
            Jack = "J",
            Queen = "Q",
            King = "K",
            Ace = "A",
        };
        rank: Rank[card % Rank.length],
        suit: Suit[Math.floor(card / Suit.length)]
        e.g: 47 ==> rank: 47 % 13 = T, suit: Math.floor(47 / 13) = 3 = c --> 10c
             48: Jc, ...

     * in Evaluator7:
        2222333344445555666677778888999910_10_10_10JJJJQQQQKKKKAAAA
        01234567..............51
        4 ranks: | Spades | Hearts | Diamonds | Clubs |
        e.g: 47 ==> rank: Math.floor(47 / 4) = K, suit: 47 % 4 = c --> Kc
        0, 4, 8, 12, 16, 1, 2 => 2s, 3s, 4s, 5s, 6s, 2h, 2d
    */

    function evaluate(uint256[] calldata cards) external view returns (uint256 score) {
        require(cards.length == 7, "invalid cards length");
        uint256[] memory transferredCards = new uint256[](7);
        for (uint256 i = 0; i < 7; ++i) {
            uint256 rank = cards[i] % 13;
            uint256 suit = cards[i] / 13;
            transferredCards[i] = rank * 4 + suit;
        }

        return Evaluator7(evaluator).evaluate(
            transferredCards[0], transferredCards[1], 
            transferredCards[2], transferredCards[3], 
            transferredCards[4], transferredCards[5], 
            transferredCards[6]);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// contract deployed separately to read the dp values for the hashing algo

contract DpTables {

uint32[8][53] public choose = [ // [uint32(53)][uint32(8)]
  [
    uint32(1),  uint32(0),  uint32(0),  uint32(0),
    uint32(0),  uint32(0),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(1),  uint32(0),  uint32(0),
    uint32(0),  uint32(0),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(2),  uint32(1),  uint32(0),
    uint32(0),  uint32(0),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(3),  uint32(3),  uint32(1),
    uint32(0),  uint32(0),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(4),  uint32(6),  uint32(4),
    uint32(1),  uint32(0),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(5),  uint32(10), uint32(10),
    uint32(5),  uint32(1),  uint32(0),  uint32(0)
  ],
  [
    uint32(1),  uint32(6),  uint32(15), uint32(20),
    uint32(15), uint32(6),  uint32(1),  uint32(0)
  ],
  [
    uint32(1),  uint32(7),  uint32(21), uint32(35),
    uint32(35), uint32(21), uint32(7),  uint32(1)
  ],
  [
    uint32(1),  uint32(8),  uint32(28), uint32(56),
    uint32(70), uint32(56), uint32(28), uint32(8)
  ],
  [
    uint32(1),  uint32(9),  uint32(36), uint32(84),
    uint32(126),  uint32(126),  uint32(84), uint32(36)
  ],
  [
    uint32(1),  uint32(10), uint32(45), uint32(120),
    uint32(210),  uint32(252),  uint32(210),  uint32(120)
  ],
  [
    uint32(1),  uint32(11), uint32(55), uint32(165),
    uint32(330),  uint32(462),  uint32(462),  uint32(330)
  ],
  [
    uint32(1),  uint32(12), uint32(66), uint32(220),
    uint32(495),  uint32(792),  uint32(924),  uint32(792)
  ],
  [
    uint32(1),  uint32(13), uint32(78), uint32(286),
    uint32(715),  uint32(1287), uint32(1716), uint32(1716)
  ],
  [
    uint32(1),  uint32(14), uint32(91), uint32(364),
    uint32(1001), uint32(2002), uint32(3003), uint32(3432)
  ],
  [
    uint32(1),  uint32(15), uint32(105),  uint32(455),
    uint32(1365), uint32(3003), uint32(5005), uint32(6435)
  ],
  [
    uint32(1),  uint32(16), uint32(120),  uint32(560),
    uint32(1820), uint32(4368), uint32(8008), uint32(11440)
  ],
  [
    uint32(1),  uint32(17), uint32(136),  uint32(680),
    uint32(2380), uint32(6188), uint32(12376),  uint32(19448)
  ],
  [
    uint32(1),  uint32(18), uint32(153),  uint32(816),
    uint32(3060), uint32(8568), uint32(18564),  uint32(31824)
  ],
  [
    uint32(1),  uint32(19), uint32(171),  uint32(969),
    uint32(3876), uint32(11628),  uint32(27132),  uint32(50388)
  ],
  [
    uint32(1),  uint32(20), uint32(190),  uint32(1140),
    uint32(4845), uint32(15504),  uint32(38760),  uint32(77520)
  ],
  [
    uint32(1),  uint32(21), uint32(210),  uint32(1330),
    uint32(5985), uint32(20349),  uint32(54264),  uint32(116280)
  ],
  [
    uint32(1),  uint32(22), uint32(231),  uint32(1540),
    uint32(7315), uint32(26334),  uint32(74613),  uint32(170544)
  ],
  [
    uint32(1),  uint32(23), uint32(253),  uint32(1771),
    uint32(8855), uint32(33649),  uint32(100947), uint32(245157)
  ],
  [
    uint32(1),  uint32(24), uint32(276),  uint32(2024),
    uint32(10626),  uint32(42504),  uint32(134596), uint32(346104)
  ],
  [
    uint32(1),  uint32(25), uint32(300),  uint32(2300),
    uint32(12650),  uint32(53130),  uint32(177100), uint32(480700)
  ],
  [
    uint32(1),  uint32(26), uint32(325),  uint32(2600),
    uint32(14950),  uint32(65780),  uint32(230230), uint32(657800)
  ],
  [
    uint32(1),  uint32(27), uint32(351),  uint32(2925),
    uint32(17550),  uint32(80730),  uint32(296010), uint32(888030)
  ],
  [
    uint32(1),  uint32(28), uint32(378),  uint32(3276),
    uint32(20475),  uint32(98280),  uint32(376740), uint32(1184040)
  ],
  [
    uint32(1),  uint32(29), uint32(406),  uint32(3654),
    uint32(23751),  uint32(118755), uint32(475020), uint32(1560780)
  ],
  [
    uint32(1),  uint32(30), uint32(435),  uint32(4060),
    uint32(27405),  uint32(142506), uint32(593775), uint32(2035800)
  ],
  [
    uint32(1),  uint32(31), uint32(465),  uint32(4495),
    uint32(31465),  uint32(169911), uint32(736281), uint32(2629575)
  ],
  [
    uint32(1),  uint32(32), uint32(496),  uint32(4960),
    uint32(35960),  uint32(201376), uint32(906192), uint32(3365856)
  ],
  [
    uint32(1),  uint32(33), uint32(528),  uint32(5456),
    uint32(40920),  uint32(237336), uint32(1107568),  uint32(4272048)
  ],
  [
    uint32(1),  uint32(34), uint32(561),  uint32(5984),
    uint32(46376),  uint32(278256), uint32(1344904),  uint32(5379616)
  ],
  [
    uint32(1),  uint32(35), uint32(595),  uint32(6545),
    uint32(52360),  uint32(324632), uint32(1623160),  uint32(6724520)
  ],
  [
    uint32(1),  uint32(36), uint32(630),  uint32(7140),
    uint32(58905),  uint32(376992), uint32(1947792),  uint32(8347680)
  ],
  [
    uint32(1),  uint32(37), uint32(666),  uint32(7770),
    uint32(66045),  uint32(435897), uint32(2324784),  uint32(10295472)
  ],
  [
    uint32(1),  uint32(38), uint32(703),  uint32(8436),
    uint32(73815),  uint32(501942), uint32(2760681),  uint32(12620256)
  ],
  [
    uint32(1),  uint32(39), uint32(741),  uint32(9139),
    uint32(82251),  uint32(575757), uint32(3262623),  uint32(15380937)
  ],
  [
    uint32(1),  uint32(40), uint32(780),  uint32(9880),
    uint32(91390),  uint32(658008), uint32(3838380),  uint32(18643560)
  ],
  [
    uint32(1),  uint32(41), uint32(820),  uint32(10660),
    uint32(101270), uint32(749398), uint32(4496388),  uint32(22481940)
  ],
  [
    uint32(1),  uint32(42), uint32(861),  uint32(11480),
    uint32(111930), uint32(850668), uint32(5245786),  uint32(26978328)
  ],
  [
    uint32(1),  uint32(43), uint32(903),  uint32(12341),
    uint32(123410), uint32(962598), uint32(6096454),  uint32(32224114)
  ],
  [
    uint32(1),  uint32(44), uint32(946),  uint32(13244),
    uint32(135751), uint32(1086008),  uint32(7059052),  uint32(38320568)
  ],
  [
    uint32(1),  uint32(45), uint32(990),  uint32(14190),
    uint32(148995), uint32(1221759),  uint32(8145060),  uint32(45379620)
  ],
  [
    uint32(1),  uint32(46), uint32(1035), uint32(15180),
    uint32(163185), uint32(1370754),  uint32(9366819),  uint32(53524680)
  ],
  [
    uint32(1),  uint32(47), uint32(1081), uint32(16215),
    uint32(178365), uint32(1533939),  uint32(10737573), uint32(62891499)
  ],
  [
    uint32(1),  uint32(48), uint32(1128), uint32(17296),
    uint32(194580), uint32(1712304),  uint32(12271512), uint32(73629072)
  ],
  [
    uint32(1),  uint32(49), uint32(1176), uint32(18424),
    uint32(211876), uint32(1906884),  uint32(13983816), uint32(85900584)
  ],
  [
    uint32(1),  uint32(50), uint32(1225), uint32(19600),
    uint32(230300), uint32(2118760),  uint32(15890700), uint32(99884400)
  ],
  [
    uint32(1),  uint32(51), uint32(1275), uint32(20825),
    uint32(249900), uint32(2349060),  uint32(18009460), uint32(115775100)
  ],
  [
    uint32(1),  uint32(52), uint32(1326), uint32(22100),
    uint32(270725), uint32(2598960),  uint32(20358520), uint32(133784560)
  ]
];

uint32[8][14][5] public dp = [ // [uint32(5)][uint32(14)][uint32(8)]
  [
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)]
  ],
  [
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(1), uint32(1),  uint32(1),  uint32(1),  uint32(1),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(1), uint32(2),  uint32(3),  uint32(4),  uint32(5),  uint32(4),  uint32(3),  uint32(2)],
    [uint32(1), uint32(3),  uint32(6),  uint32(10), uint32(15), uint32(18), uint32(19), uint32(18)],
    [uint32(1), uint32(4),  uint32(10), uint32(20), uint32(35), uint32(52), uint32(68), uint32(80)],
    [uint32(1), uint32(5),  uint32(15), uint32(35), uint32(70), uint32(121),  uint32(185),  uint32(255)],
    [uint32(1), uint32(6),  uint32(21), uint32(56), uint32(126),  uint32(246),  uint32(426),  uint32(666)],
    [uint32(1), uint32(7),  uint32(28), uint32(84), uint32(210),  uint32(455),  uint32(875),  uint32(1520)],
    [uint32(1), uint32(8),  uint32(36), uint32(120),  uint32(330),  uint32(784),  uint32(1652), uint32(3144)],
    [uint32(1), uint32(9),  uint32(45), uint32(165),  uint32(495),  uint32(1278), uint32(2922), uint32(6030)],
    [uint32(1), uint32(10), uint32(55), uint32(220),  uint32(715),  uint32(1992), uint32(4905), uint32(10890)],
    [uint32(1), uint32(11), uint32(66), uint32(286),  uint32(1001), uint32(2992), uint32(7887), uint32(18722)],
    [uint32(1), uint32(12), uint32(78), uint32(364),  uint32(1365), uint32(4356), uint32(12232),  uint32(30888)],
    [uint32(1), uint32(13), uint32(91), uint32(455),  uint32(1820), uint32(6175), uint32(18395),  uint32(49205)]
  ],
  [
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(1), uint32(2),  uint32(2),  uint32(2),  uint32(2),  uint32(1),  uint32(0),  uint32(0)],
    [uint32(1), uint32(3),  uint32(5),  uint32(7),  uint32(9),  uint32(9),  uint32(7),  uint32(5)],
    [uint32(1), uint32(4),  uint32(9),  uint32(16), uint32(25), uint32(33), uint32(37), uint32(37)],
    [uint32(1), uint32(5),  uint32(14), uint32(30), uint32(55), uint32(87), uint32(120),  uint32(148)],
    [uint32(1), uint32(6),  uint32(20), uint32(50), uint32(105),  uint32(191),  uint32(306),  uint32(440)],
    [uint32(1), uint32(7),  uint32(27), uint32(77), uint32(182),  uint32(372),  uint32(672),  uint32(1092)],
    [uint32(1), uint32(8),  uint32(35), uint32(112),  uint32(294),  uint32(665),  uint32(1330), uint32(2395)],
    [uint32(1), uint32(9),  uint32(44), uint32(156),  uint32(450),  uint32(1114), uint32(2436), uint32(4796)],
    [uint32(1), uint32(10), uint32(54), uint32(210),  uint32(660),  uint32(1773), uint32(4200), uint32(8952)],
    [uint32(1), uint32(11), uint32(65), uint32(275),  uint32(935),  uint32(2707), uint32(6897), uint32(15795)],
    [uint32(1), uint32(12), uint32(77), uint32(352),  uint32(1287), uint32(3993), uint32(10879),  uint32(26609)],
    [uint32(1), uint32(13), uint32(90), uint32(442),  uint32(1729), uint32(5721), uint32(16588),  uint32(43120)],
    [uint32(1), uint32(14), uint32(104),  uint32(546),  uint32(2275), uint32(7995), uint32(24570),  uint32(67600)]
  ],
  [
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(1), uint32(2),  uint32(3),  uint32(3),  uint32(3),  uint32(2),  uint32(1),  uint32(0)],
    [uint32(1), uint32(3),  uint32(6),  uint32(9),  uint32(12), uint32(13), uint32(12), uint32(9)],
    [uint32(1), uint32(4),  uint32(10), uint32(19), uint32(31), uint32(43), uint32(52), uint32(55)],
    [uint32(1), uint32(5),  uint32(15), uint32(34), uint32(65), uint32(107),  uint32(155),  uint32(200)],
    [uint32(1), uint32(6),  uint32(21), uint32(55), uint32(120),  uint32(226),  uint32(376),  uint32(561)],
    [uint32(1), uint32(7),  uint32(28), uint32(83), uint32(203),  uint32(428),  uint32(798),  uint32(1338)],
    [uint32(1), uint32(8),  uint32(36), uint32(119),  uint32(322),  uint32(749),  uint32(1540), uint32(2850)],
    [uint32(1), uint32(9),  uint32(45), uint32(164),  uint32(486),  uint32(1234), uint32(2766), uint32(5580)],
    [uint32(1), uint32(10), uint32(55), uint32(219),  uint32(705),  uint32(1938), uint32(4695), uint32(10230)],
    [uint32(1), uint32(11), uint32(66), uint32(285),  uint32(990),  uint32(2927), uint32(7612), uint32(17787)],
    [uint32(1), uint32(12), uint32(78), uint32(363),  uint32(1353), uint32(4279), uint32(11880),  uint32(29601)],
    [uint32(1), uint32(13), uint32(91), uint32(454),  uint32(1807), uint32(6085), uint32(17953),  uint32(47476)],
    [uint32(1), uint32(14), uint32(105),  uint32(559),  uint32(2366), uint32(8450), uint32(26390),  uint32(73775)]
  ],
  [
    [uint32(0), uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0),  uint32(0)],
    [uint32(1), uint32(2),  uint32(3),  uint32(4),  uint32(4),  uint32(3),  uint32(2),  uint32(1)],
    [uint32(1), uint32(3),  uint32(6),  uint32(10), uint32(14), uint32(16), uint32(16), uint32(14)],
    [uint32(1), uint32(4),  uint32(10), uint32(20), uint32(34), uint32(49), uint32(62), uint32(70)],
    [uint32(1), uint32(5),  uint32(15), uint32(35), uint32(69), uint32(117),  uint32(175),  uint32(235)],
    [uint32(1), uint32(6),  uint32(21), uint32(56), uint32(125),  uint32(241),  uint32(411),  uint32(631)],
    [uint32(1), uint32(7),  uint32(28), uint32(84), uint32(209),  uint32(449),  uint32(854),  uint32(1464)],
    [uint32(1), uint32(8),  uint32(36), uint32(120),  uint32(329),  uint32(777),  uint32(1624), uint32(3060)],
    [uint32(1), uint32(9),  uint32(45), uint32(165),  uint32(494),  uint32(1270), uint32(2886), uint32(5910)],
    [uint32(1), uint32(10), uint32(55), uint32(220),  uint32(714),  uint32(1983), uint32(4860), uint32(10725)],
    [uint32(1), uint32(11), uint32(66), uint32(286),  uint32(1000), uint32(2982), uint32(7832), uint32(18502)],
    [uint32(1), uint32(12), uint32(78), uint32(364),  uint32(1364), uint32(4345), uint32(12166),  uint32(30602)],
    [uint32(1), uint32(13), uint32(91), uint32(455),  uint32(1819), uint32(6163), uint32(18317),  uint32(48841)],
    [uint32(1), uint32(14), uint32(105),  uint32(560),  uint32(2379), uint32(8541), uint32(26845),  uint32(75595)]
  ]
];

  uint32[] public suits;

  function appendSuits(uint32[] calldata suits_) external {
    for (uint256 i = 0; i < suits_.length; ++i) {
      suits.push(suits_[i]);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {DpTables} from "./DpTables.sol";

import {Flush1} from "./flush/Flush1.sol";
import {Flush2} from "./flush/Flush2.sol";
import {Flush3} from "./flush/Flush3.sol";

import {NoFlush1} from "./noFlush/NoFlush1.sol";
import {NoFlush2} from "./noFlush/NoFlush2.sol";
import {NoFlush3} from "./noFlush/NoFlush3.sol";
import {NoFlush4} from "./noFlush/NoFlush4.sol";
import {NoFlush5} from "./noFlush/NoFlush5.sol";
import {NoFlush6} from "./noFlush/NoFlush6.sol";
import {NoFlush7} from "./noFlush/NoFlush7.sol";
import {NoFlush8} from "./noFlush/NoFlush8.sol";
import {NoFlush9} from "./noFlush/NoFlush9.sol";
import {NoFlush10} from "./noFlush/NoFlush10.sol";
import {NoFlush11} from "./noFlush/NoFlush11.sol";
import {NoFlush12} from "./noFlush/NoFlush12.sol";
import {NoFlush13} from "./noFlush/NoFlush13.sol";
import {NoFlush14} from "./noFlush/NoFlush14.sol";
import {NoFlush15} from "./noFlush/NoFlush15.sol";
import {NoFlush16} from "./noFlush/NoFlush16.sol";
import {NoFlush17} from "./noFlush/NoFlush17.sol";

contract Evaluator7 {

    address public immutable DP_TABLES;
    address[3] public  FLUSH_ADDRESSES;
    address[17] public NOFLUSH_ADDRESSES;

    uint8 STRAIGHT_FLUSH  = 0;
    uint8 FOUR_OF_A_KIND  = 1;
    uint8 FULL_HOUSE      = 2;
    uint8 FLUSH           = 3;
    uint8 STRAIGHT        = 4;
    uint8 THREE_OF_A_KIND = 5;
    uint8 TWO_PAIR        = 6;
    uint8 ONE_PAIR        = 7;
    uint8 HIGH_CARD       = 8;

    uint[52] public binaries_by_id = [  // 52
        0x1,  0x1,  0x1,  0x1,
        0x2,  0x2,  0x2,  0x2,
        0x4,  0x4,  0x4,  0x4,
        0x8,  0x8,  0x8,  0x8,
        0x10, 0x10, 0x10, 0x10,
        0x20, 0x20, 0x20, 0x20,
        0x40, 0x40, 0x40, 0x40,
        0x80, 0x80, 0x80, 0x80,
        0x100,  0x100,  0x100,  0x100,
        0x200,  0x200,  0x200,  0x200,
        0x400,  0x400,  0x400,  0x400,
        0x800,  0x800,  0x800,  0x800,
        0x1000, 0x1000, 0x1000, 0x1000
    ];

    uint[52] public suitbit_by_id = [ // 52
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200,
        0x1,  0x8,  0x40, 0x200
    ];

    constructor(address _dpTables, address[3] memory _flushes, address[17] memory _noflushes)  {
        DP_TABLES = _dpTables;

        for (uint i=0; i<_flushes.length; i++) {
            FLUSH_ADDRESSES[i] = _flushes[i];
        }

        for (uint j=0; j<_noflushes.length; j++) {
            NOFLUSH_ADDRESSES[j] = _noflushes[j];
        }
    }


    function handRankV2(uint[7] calldata cards) public view returns (uint8) {
        return handRank(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]);
    }

    function handRank(uint a, uint b, uint c, uint d, uint e, uint f, uint g) public view returns (uint8) {
        uint val = evaluate(a,b,c,d,e,f,g);

        if (val > 6185) return HIGH_CARD;        // 1277 high card
        if (val > 3325) return ONE_PAIR;        // 2860 one pair
        if (val > 2467) return TWO_PAIR;         //  858 two pair
        if (val > 1609) return THREE_OF_A_KIND;  //  858 three-kind
        if (val > 1599) return STRAIGHT;         //   10 straights
        if (val > 322)  return FLUSH;            // 1277 flushes
        if (val > 166)  return FULL_HOUSE;       //  156 full house
        if (val > 10)   return FOUR_OF_A_KIND;   //  156 four-kind
        return STRAIGHT_FLUSH;                   //   10 straight-flushes
    }

    function evaluateV2(uint[7] calldata cards) public view returns (uint) {
        return evaluate(cards[0], cards[1], cards[2], cards[3], cards[4], cards[5], cards[6]);
    }

    function evaluate(uint a, uint b, uint c , uint d, uint e, uint f, uint g) public view returns (uint) {
        uint suit_hash = 0;
        uint[4] memory suit_binary = [ uint(0), uint(0), uint(0), uint(0) ]; // 4
        uint8[13] memory quinary = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]; // 13
        uint hsh;

        suit_hash += suitbit_by_id[a];
        quinary[(a >> 2)]++;
        suit_hash += suitbit_by_id[b];
        quinary[(b >> 2)]++;
        suit_hash += suitbit_by_id[c];
        quinary[(c >> 2)]++;
        suit_hash += suitbit_by_id[d];
        quinary[(d >> 2)]++;
        suit_hash += suitbit_by_id[e];
        quinary[(e >> 2)]++;
        suit_hash += suitbit_by_id[f];
        quinary[(f >> 2)]++;
        suit_hash += suitbit_by_id[g];
        quinary[(g >> 2)]++;

        uint suits = DpTables(DP_TABLES).suits(suit_hash);

        if (suits > 0) {
            suit_binary[a & 0x3] |= binaries_by_id[a];
            suit_binary[b & 0x3] |= binaries_by_id[b];
            suit_binary[c & 0x3] |= binaries_by_id[c];
            suit_binary[d & 0x3] |= binaries_by_id[d];
            suit_binary[e & 0x3] |= binaries_by_id[e];
            suit_binary[f & 0x3] |= binaries_by_id[f];
            suit_binary[g & 0x3] |= binaries_by_id[g];

            uint sb = suit_binary[suits - 1];

            if (sb < 3000) {
                return Flush1(FLUSH_ADDRESSES[0]).flush(sb);
            } else if (sb < 6000) {
                return Flush2(FLUSH_ADDRESSES[1]).flush(sb - 3000);
            } else {
                return Flush3(FLUSH_ADDRESSES[2]).flush(sb - 6000);
            }

        }     

        hsh = hash_quinary(quinary, 13, 7); // buggy!!

        if (hsh < 3000) {
            return NoFlush1(NOFLUSH_ADDRESSES[0]).noflush(hsh);
        } else if (hsh < 6000 ) {
            return NoFlush2(NOFLUSH_ADDRESSES[1]).noflush(hsh - 3000);

        } else if (hsh < 9000) {
            return NoFlush3(NOFLUSH_ADDRESSES[2]).noflush(hsh - 6000);

        } else if (hsh < 12000) {
            return NoFlush4(NOFLUSH_ADDRESSES[3]).noflush(hsh - 9000);

        } else if (hsh < 15000) {
            return NoFlush5(NOFLUSH_ADDRESSES[4]).noflush(hsh - 12000);

        } else if (hsh < 18000) {
            return NoFlush6(NOFLUSH_ADDRESSES[5]).noflush(hsh - 15000);

        } else if (hsh < 21000) {
            return NoFlush7(NOFLUSH_ADDRESSES[6]).noflush(hsh - 18000);

        } else if (hsh < 24000) {
            return NoFlush8(NOFLUSH_ADDRESSES[7]).noflush(hsh - 21000);

        } else if (hsh < 27000) {
            return NoFlush9(NOFLUSH_ADDRESSES[8]).noflush(hsh - 24000);

        } else if (hsh < 30000) {
            return NoFlush10(NOFLUSH_ADDRESSES[9]).noflush(hsh - 27000);

        } else if (hsh < 33000) {
            return NoFlush11(NOFLUSH_ADDRESSES[10]).noflush(hsh - 30000);

        } else if (hsh < 36000) {
            return NoFlush12(NOFLUSH_ADDRESSES[11]).noflush(hsh - 33000);

        } else if (hsh < 39000) {
            return NoFlush13(NOFLUSH_ADDRESSES[12]).noflush(hsh - 36000);

        } else if (hsh < 42000) {
            return NoFlush14(NOFLUSH_ADDRESSES[13]).noflush(hsh - 39000);

        } else if (hsh < 45000) {
            return NoFlush15(NOFLUSH_ADDRESSES[14]).noflush(hsh - 42000);

        } else if (hsh < 48000) {
            return NoFlush16(NOFLUSH_ADDRESSES[15]).noflush(hsh - 45000);
        } else {
            return NoFlush17(NOFLUSH_ADDRESSES[16]).noflush(hsh - 48000);
        }

    }

    function hash_quinary(uint8[13] memory q, uint len, uint k) public view returns (uint sum) {

        for (uint i = 0; i < len; i++) {
            sum += DpTables(DP_TABLES).dp(q[i], (len - i - 1), k);

            k -= q[i];

            if (k <= 0) break;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Flush1 {
    uint16[] public flush;

    // calldata can't be larger than 40000 bytes
    function appendFlush(uint16[] calldata flushes) external {
      for (uint i = 0; i < flushes.length; ++i) {
        flush.push(flushes[i]);
      }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Flush2 {
    uint16[] public flush;

    // calldata can't be larger than 40000 bytes
    function appendFlush(uint16[] calldata flushes) external {
      for (uint i = 0; i < flushes.length; ++i) {
        flush.push(flushes[i]);
      }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Flush3 {
    uint16[] public flush;

    // calldata can't be larger than 40000 bytes
    function appendFlush(uint16[] calldata flushes) external {
      for (uint i = 0; i < flushes.length; ++i) {
        flush.push(flushes[i]);
      }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush1 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush10 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush11 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush12 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush13 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush14 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush15 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush16 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush17 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush2 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush3 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush4 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush5 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush6 {
     uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush7 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush8 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush9 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}