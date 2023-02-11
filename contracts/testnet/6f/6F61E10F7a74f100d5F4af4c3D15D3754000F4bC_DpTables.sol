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