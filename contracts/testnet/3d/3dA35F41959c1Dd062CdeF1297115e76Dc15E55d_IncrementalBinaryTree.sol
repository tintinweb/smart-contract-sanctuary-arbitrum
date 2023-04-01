// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "poseidon-solidity/PoseidonT3.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
    bool useDefaultZeroes;
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 public constant Z_0 = 0;
    uint256 public constant Z_1 = 14744269619966411208579211824598458697587494354926760081771325075741142829156;
    uint256 public constant Z_2 = 7423237065226347324353380772367382631490014989348495481811164164159255474657;
    uint256 public constant Z_3 = 11286972368698509976183087595462810875513684078608517520839298933882497716792;
    uint256 public constant Z_4 = 3607627140608796879659380071776844901612302623152076817094415224584923813162;
    uint256 public constant Z_5 = 19712377064642672829441595136074946683621277828620209496774504837737984048981;
    uint256 public constant Z_6 = 20775607673010627194014556968476266066927294572720319469184847051418138353016;
    uint256 public constant Z_7 = 3396914609616007258851405644437304192397291162432396347162513310381425243293;
    uint256 public constant Z_8 = 21551820661461729022865262380882070649935529853313286572328683688269863701601;
    uint256 public constant Z_9 = 6573136701248752079028194407151022595060682063033565181951145966236778420039;
    uint256 public constant Z_10 = 12413880268183407374852357075976609371175688755676981206018884971008854919922;
    uint256 public constant Z_11 = 14271763308400718165336499097156975241954733520325982997864342600795471836726;
    uint256 public constant Z_12 = 20066985985293572387227381049700832219069292839614107140851619262827735677018;
    uint256 public constant Z_13 = 9394776414966240069580838672673694685292165040808226440647796406499139370960;
    uint256 public constant Z_14 = 11331146992410411304059858900317123658895005918277453009197229807340014528524;
    uint256 public constant Z_15 = 15819538789928229930262697811477882737253464456578333862691129291651619515538;
    uint256 public constant Z_16 = 19217088683336594659449020493828377907203207941212636669271704950158751593251;
    uint256 public constant Z_17 = 21035245323335827719745544373081896983162834604456827698288649288827293579666;
    uint256 public constant Z_18 = 6939770416153240137322503476966641397417391950902474480970945462551409848591;
    uint256 public constant Z_19 = 10941962436777715901943463195175331263348098796018438960955633645115732864202;
    uint256 public constant Z_20 = 15019797232609675441998260052101280400536945603062888308240081994073687793470;
    uint256 public constant Z_21 = 11702828337982203149177882813338547876343922920234831094975924378932809409969;
    uint256 public constant Z_22 = 11217067736778784455593535811108456786943573747466706329920902520905755780395;
    uint256 public constant Z_23 = 16072238744996205792852194127671441602062027943016727953216607508365787157389;
    uint256 public constant Z_24 = 17681057402012993898104192736393849603097507831571622013521167331642182653248;
    uint256 public constant Z_25 = 21694045479371014653083846597424257852691458318143380497809004364947786214945;
    uint256 public constant Z_26 = 8163447297445169709687354538480474434591144168767135863541048304198280615192;
    uint256 public constant Z_27 = 14081762237856300239452543304351251708585712948734528663957353575674639038357;
    uint256 public constant Z_28 = 16619959921569409661790279042024627172199214148318086837362003702249041851090;
    uint256 public constant Z_29 = 7022159125197495734384997711896547675021391130223237843255817587255104160365;
    uint256 public constant Z_30 = 4114686047564160449611603615418567457008101555090703535405891656262658644463;
    uint256 public constant Z_31 = 12549363297364877722388257367377629555213421373705596078299904496781819142130;
    uint256 public constant Z_32 = 21443572485391568159800782191812935835534334817699172242223315142338162256601;

    function defaultZero(uint256 index) public pure returns (uint256) {
        if (index == 0) return Z_0;
        if (index == 1) return Z_1;
        if (index == 2) return Z_2;
        if (index == 3) return Z_3;
        if (index == 4) return Z_4;
        if (index == 5) return Z_5;
        if (index == 6) return Z_6;
        if (index == 7) return Z_7;
        if (index == 8) return Z_8;
        if (index == 9) return Z_9;
        if (index == 10) return Z_10;
        if (index == 11) return Z_11;
        if (index == 12) return Z_12;
        if (index == 13) return Z_13;
        if (index == 14) return Z_14;
        if (index == 15) return Z_15;
        if (index == 16) return Z_16;
        if (index == 17) return Z_17;
        if (index == 18) return Z_18;
        if (index == 19) return Z_19;
        if (index == 20) return Z_20;
        if (index == 21) return Z_21;
        if (index == 22) return Z_22;
        if (index == 23) return Z_23;
        if (index == 24) return Z_24;
        if (index == 25) return Z_25;
        if (index == 26) return Z_26;
        if (index == 27) return Z_27;
        if (index == 28) return Z_28;
        if (index == 29) return Z_29;
        if (index == 30) return Z_30;
        if (index == 31) return Z_31;
        if (index == 32) return Z_32;
        revert("IncrementalBinaryTree: defaultZero bad index");
    }

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.hash([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    function initWithDefaultZeroes(IncrementalTreeData storage self, uint256 depth) public {
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;
        self.useDefaultZeroes = true;

        self.root = defaultZero(depth);
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public returns (uint256) {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;
        bool useDefaultZeroes = self.useDefaultZeroes;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, useDefaultZeroes ? defaultZero(i) : self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.hash(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
        return hash;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(newLeaf != leaf, "IncrementalBinaryTree: new leaf cannot be the same as the old one");
        require(newLeaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: new leaf must be < SNARK_SCALAR_FIELD");
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;
        uint256 updateIndex;

        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.hash([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.hash([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.useDefaultZeroes ? Z_0 : self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.hash([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.hash([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library PoseidonT3 {
  uint constant F = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  uint constant M00 = 0x109b7f411ba0e4c9b2b70caf5c36a7b194be7c11ad24378bfedb68592ba8118b;
  uint constant M01 = 0x2969f27eed31a480b9c36c764379dbca2cc8fdd1415c3dded62940bcde0bd771;
  uint constant M02 = 0x143021ec686a3f330d5f9e654638065ce6cd79e28c5b3753326244ee65a1b1a7;
  uint constant M10 = 0x16ed41e13bb9c0c66ae119424fddbcbc9314dc9fdbdeea55d6c64543dc4903e0;
  uint constant M11 = 0x2e2419f9ec02ec394c9871c832963dc1b89d743c8c7b964029b2311687b1fe23;
  uint constant M12 = 0x176cc029695ad02582a70eff08a6fd99d057e12e58e7d7b6b16cdfabc8ee2911;
  uint constant M20 = 0x2b90bba00fca0589f617e7dcbfe82e0df706ab640ceb247b791a93b74e36736d;
  uint constant M21 = 0x101071f0032379b697315876690f053d148d4e109f5fb065c8aacc55a0f89bfa;
  uint constant M22 = 0x19a3fc0a56702bf417ba7fee3802593fa644470307043f7773279cd71d25d5e0;

  // See here for a simplified implementation: https://github.com/vimwitch/poseidon-solidity/blob/e57becdabb65d99fdc586fe1e1e09e7108202d53/contracts/Poseidon.sol#L40
  // Based on: https://github.com/iden3/circomlibjs/blob/v0.0.8/src/poseidon_slow.js
  function hash(uint[2] memory) public pure returns (uint) {
    assembly {
      // memory 0x00 to 0x3f (64 bytes) is scratch space for hash algos
      // we can use it in inline assembly because we're not calling e.g. keccak
      //
      // memory 0x80 is the default offset for free memory
      // we take inputs as a memory argument so we simply write over
      // that memory after loading it

      // we have the following variables at memory offsets
      // state0 - 0x00
      // state1 - 0x20
      // state2 - 0x80
      // state3 - 0xa0
      // state4 - ...

      function pRound(c0, c1, c2) {
        let state0 := addmod(mload(0x0), c0, F)
        let state1 := addmod(mload(0x20), c1, F)
        let state2 := addmod(mload(0x80), c2, F)

        let p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)

        mstore(0x0, addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F))
        mstore(0x20, addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F))
        mstore(0x80, addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F))
      }

      function fRound(c0, c1, c2) {
        let state0 := addmod(mload(0x0), c0, F)
        let state1 := addmod(mload(0x20), c1, F)
        let state2 := addmod(mload(0x80), c2, F)

        let p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)
        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)
        p := mulmod(state2, state2, F)
        state2 := mulmod(mulmod(p, p, F), state2, F)

        mstore(0x0, addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F))
        mstore(0x20, addmod(addmod(mulmod(state0, M01, F), mulmod(state1, M11, F), F), mulmod(state2, M21, F), F))
        mstore(0x80, addmod(addmod(mulmod(state0, M02, F), mulmod(state1, M12, F), F), mulmod(state2, M22, F), F))
      }

      // scratch variable for exponentiation
      let p

      {
        // load the inputs from memory
        let state1 := addmod(mload(0x80), 0x00f1445235f2148c5986587169fc1bcd887b08d4d00868df5696fff40956e864, F)
        let state2 := addmod(mload(0xa0), 0x08dff3487e8ac99e1f29a058d0fa80b930c728730b7ab36ce879f3890ecf73f5, F)
        mstore(0x60, addmod(mload(0xc0), 0x2f27be690fdaee46c3ce28f7532b13c856c35342c84bda6e20966310fadc01d0, F))

        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)
        p := mulmod(state2, state2, F)
        state2 := mulmod(mulmod(p, p, F), state2, F)

        // state0 pow5mod and M[] multiplications are pre-calculated

        mstore(0x0, addmod(addmod(0x2229fe5e63f56eef4bfba02c26292de10ac2b2b045e6184acff16e4660c05f6b, mulmod(state1, M10, F), F), mulmod(state2, M20, F), F))
        mstore(0x20, addmod(addmod(0x2949435275a29cdbffe3e4101a45669873f9408a5d11e21b4ec6edf8501eee4d, mulmod(state1, M11, F), F), mulmod(state2, M21, F), F))
        mstore(0x80, addmod(addmod(0x20c290a7269657965092ef5700a447f5bc2c41dfca932f527cb2600ac9bcfefb, mulmod(state1, M12, F), F), mulmod(state2, M22, F), F))
      }

      fRound(
        0x2f27be690fdaee46c3ce28f7532b13c856c35342c84bda6e20966310fadc01d0,
        0x2b2ae1acf68b7b8d2416bebf3d4f6234b763fe04b8043ee48b8327bebca16cf2,
        0x0319d062072bef7ecca5eac06f97d4d55952c175ab6b03eae64b44c7dbf11cfa
      )

      fRound(
        0x28813dcaebaeaa828a376df87af4a63bc8b7bf27ad49c6298ef7b387bf28526d,
        0x2727673b2ccbc903f181bf38e1c1d40d2033865200c352bc150928adddf9cb78,
        0x234ec45ca27727c2e74abd2b2a1494cd6efbd43e340587d6b8fb9e31e65cc632
      )

      fRound(
        0x15b52534031ae18f7f862cb2cf7cf760ab10a8150a337b1ccd99ff6e8797d428,
        0x0dc8fad6d9e4b35f5ed9a3d186b79ce38e0e8a8d1b58b132d701d4eecf68d1f6,
        0x1bcd95ffc211fbca600f705fad3fb567ea4eb378f62e1fec97805518a47e4d9c
      )

      pRound(
        0x10520b0ab721cadfe9eff81b016fc34dc76da36c2578937817cb978d069de559,
        0x1f6d48149b8e7f7d9b257d8ed5fbbaf42932498075fed0ace88a9eb81f5627f6,
        0x1d9655f652309014d29e00ef35a2089bfff8dc1c816f0dc9ca34bdb5460c8705
      )

      pRound(
        0x04df5a56ff95bcafb051f7b1cd43a99ba731ff67e47032058fe3d4185697cc7d,
        0x0672d995f8fff640151b3d290cedaf148690a10a8c8424a7f6ec282b6e4be828,
        0x099952b414884454b21200d7ffafdd5f0c9a9dcc06f2708e9fc1d8209b5c75b9
      )

      pRound(
        0x052cba2255dfd00c7c483143ba8d469448e43586a9b4cd9183fd0e843a6b9fa6,
        0x0b8badee690adb8eb0bd74712b7999af82de55707251ad7716077cb93c464ddc,
        0x119b1590f13307af5a1ee651020c07c749c15d60683a8050b963d0a8e4b2bdd1
      )

      pRound(
        0x03150b7cd6d5d17b2529d36be0f67b832c4acfc884ef4ee5ce15be0bfb4a8d09,
        0x2cc6182c5e14546e3cf1951f173912355374efb83d80898abe69cb317c9ea565,
        0x005032551e6378c450cfe129a404b3764218cadedac14e2b92d2cd73111bf0f9
      )

      pRound(
        0x233237e3289baa34bb147e972ebcb9516469c399fcc069fb88f9da2cc28276b5,
        0x05c8f4f4ebd4a6e3c980d31674bfbe6323037f21b34ae5a4e80c2d4c24d60280,
        0x0a7b1db13042d396ba05d818a319f25252bcf35ef3aeed91ee1f09b2590fc65b
      )

      pRound(
        0x2a73b71f9b210cf5b14296572c9d32dbf156e2b086ff47dc5df542365a404ec0,
        0x1ac9b0417abcc9a1935107e9ffc91dc3ec18f2c4dbe7f22976a760bb5c50c460,
        0x12c0339ae08374823fabb076707ef479269f3e4d6cb104349015ee046dc93fc0
      )

      pRound(
        0x0b7475b102a165ad7f5b18db4e1e704f52900aa3253baac68246682e56e9a28e,
        0x037c2849e191ca3edb1c5e49f6e8b8917c843e379366f2ea32ab3aa88d7f8448,
        0x05a6811f8556f014e92674661e217e9bd5206c5c93a07dc145fdb176a716346f
      )

      pRound(
        0x29a795e7d98028946e947b75d54e9f044076e87a7b2883b47b675ef5f38bd66e,
        0x20439a0c84b322eb45a3857afc18f5826e8c7382c8a1585c507be199981fd22f,
        0x2e0ba8d94d9ecf4a94ec2050c7371ff1bb50f27799a84b6d4a2a6f2a0982c887
      )

      pRound(
        0x143fd115ce08fb27ca38eb7cce822b4517822cd2109048d2e6d0ddcca17d71c8,
        0x0c64cbecb1c734b857968dbbdcf813cdf8611659323dbcbfc84323623be9caf1,
        0x028a305847c683f646fca925c163ff5ae74f348d62c2b670f1426cef9403da53
      )

      pRound(
        0x2e4ef510ff0b6fda5fa940ab4c4380f26a6bcb64d89427b824d6755b5db9e30c,
        0x0081c95bc43384e663d79270c956ce3b8925b4f6d033b078b96384f50579400e,
        0x2ed5f0c91cbd9749187e2fade687e05ee2491b349c039a0bba8a9f4023a0bb38
      )

      pRound(
        0x30509991f88da3504bbf374ed5aae2f03448a22c76234c8c990f01f33a735206,
        0x1c3f20fd55409a53221b7c4d49a356b9f0a1119fb2067b41a7529094424ec6ad,
        0x10b4e7f3ab5df003049514459b6e18eec46bb2213e8e131e170887b47ddcb96c
      )

      pRound(
        0x2a1982979c3ff7f43ddd543d891c2abddd80f804c077d775039aa3502e43adef,
        0x1c74ee64f15e1db6feddbead56d6d55dba431ebc396c9af95cad0f1315bd5c91,
        0x07533ec850ba7f98eab9303cace01b4b9e4f2e8b82708cfa9c2fe45a0ae146a0
      )

      pRound(
        0x21576b438e500449a151e4eeaf17b154285c68f42d42c1808a11abf3764c0750,
        0x2f17c0559b8fe79608ad5ca193d62f10bce8384c815f0906743d6930836d4a9e,
        0x2d477e3862d07708a79e8aae946170bc9775a4201318474ae665b0b1b7e2730e
      )

      pRound(
        0x162f5243967064c390e095577984f291afba2266c38f5abcd89be0f5b2747eab,
        0x2b4cb233ede9ba48264ecd2c8ae50d1ad7a8596a87f29f8a7777a70092393311,
        0x2c8fbcb2dd8573dc1dbaf8f4622854776db2eece6d85c4cf4254e7c35e03b07a
      )

      pRound(
        0x1d6f347725e4816af2ff453f0cd56b199e1b61e9f601e9ade5e88db870949da9,
        0x204b0c397f4ebe71ebc2d8b3df5b913df9e6ac02b68d31324cd49af5c4565529,
        0x0c4cb9dc3c4fd8174f1149b3c63c3c2f9ecb827cd7dc25534ff8fb75bc79c502
      )

      pRound(
        0x174ad61a1448c899a25416474f4930301e5c49475279e0639a616ddc45bc7b54,
        0x1a96177bcf4d8d89f759df4ec2f3cde2eaaa28c177cc0fa13a9816d49a38d2ef,
        0x066d04b24331d71cd0ef8054bc60c4ff05202c126a233c1a8242ace360b8a30a
      )

      pRound(
        0x2a4c4fc6ec0b0cf52195782871c6dd3b381cc65f72e02ad527037a62aa1bd804,
        0x13ab2d136ccf37d447e9f2e14a7cedc95e727f8446f6d9d7e55afc01219fd649,
        0x1121552fca26061619d24d843dc82769c1b04fcec26f55194c2e3e869acc6a9a
      )

      pRound(
        0x00ef653322b13d6c889bc81715c37d77a6cd267d595c4a8909a5546c7c97cff1,
        0x0e25483e45a665208b261d8ba74051e6400c776d652595d9845aca35d8a397d3,
        0x29f536dcb9dd7682245264659e15d88e395ac3d4dde92d8c46448db979eeba89
      )

      pRound(
        0x2a56ef9f2c53febadfda33575dbdbd885a124e2780bbea170e456baace0fa5be,
        0x1c8361c78eb5cf5decfb7a2d17b5c409f2ae2999a46762e8ee416240a8cb9af1,
        0x151aff5f38b20a0fc0473089aaf0206b83e8e68a764507bfd3d0ab4be74319c5
      )

      pRound(
        0x04c6187e41ed881dc1b239c88f7f9d43a9f52fc8c8b6cdd1e76e47615b51f100,
        0x13b37bd80f4d27fb10d84331f6fb6d534b81c61ed15776449e801b7ddc9c2967,
        0x01a5c536273c2d9df578bfbd32c17b7a2ce3664c2a52032c9321ceb1c4e8a8e4
      )

      pRound(
        0x2ab3561834ca73835ad05f5d7acb950b4a9a2c666b9726da832239065b7c3b02,
        0x1d4d8ec291e720db200fe6d686c0d613acaf6af4e95d3bf69f7ed516a597b646,
        0x041294d2cc484d228f5784fe7919fd2bb925351240a04b711514c9c80b65af1d
      )

      pRound(
        0x154ac98e01708c611c4fa715991f004898f57939d126e392042971dd90e81fc6,
        0x0b339d8acca7d4f83eedd84093aef51050b3684c88f8b0b04524563bc6ea4da4,
        0x0955e49e6610c94254a4f84cfbab344598f0e71eaff4a7dd81ed95b50839c82e
      )

      pRound(
        0x06746a6156eba54426b9e22206f15abca9a6f41e6f535c6f3525401ea0654626,
        0x0f18f5a0ecd1423c496f3820c549c27838e5790e2bd0a196ac917c7ff32077fb,
        0x04f6eeca1751f7308ac59eff5beb261e4bb563583ede7bc92a738223d6f76e13
      )

      pRound(
        0x2b56973364c4c4f5c1a3ec4da3cdce038811eb116fb3e45bc1768d26fc0b3758,
        0x123769dd49d5b054dcd76b89804b1bcb8e1392b385716a5d83feb65d437f29ef,
        0x2147b424fc48c80a88ee52b91169aacea989f6446471150994257b2fb01c63e9
      )

      pRound(
        0x0fdc1f58548b85701a6c5505ea332a29647e6f34ad4243c2ea54ad897cebe54d,
        0x12373a8251fea004df68abcf0f7786d4bceff28c5dbbe0c3944f685cc0a0b1f2,
        0x21e4f4ea5f35f85bad7ea52ff742c9e8a642756b6af44203dd8a1f35c1a90035
      )

      pRound(
        0x16243916d69d2ca3dfb4722224d4c462b57366492f45e90d8a81934f1bc3b147,
        0x1efbe46dd7a578b4f66f9adbc88b4378abc21566e1a0453ca13a4159cac04ac2,
        0x07ea5e8537cf5dd08886020e23a7f387d468d5525be66f853b672cc96a88969a
      )

      pRound(
        0x05a8c4f9968b8aa3b7b478a30f9a5b63650f19a75e7ce11ca9fe16c0b76c00bc,
        0x20f057712cc21654fbfe59bd345e8dac3f7818c701b9c7882d9d57b72a32e83f,
        0x04a12ededa9dfd689672f8c67fee31636dcd8e88d01d49019bd90b33eb33db69
      )

      pRound(
        0x27e88d8c15f37dcee44f1e5425a51decbd136ce5091a6767e49ec9544ccd101a,
        0x2feed17b84285ed9b8a5c8c5e95a41f66e096619a7703223176c41ee433de4d1,
        0x1ed7cc76edf45c7c404241420f729cf394e5942911312a0d6972b8bd53aff2b8
      )

      pRound(
        0x15742e99b9bfa323157ff8c586f5660eac6783476144cdcadf2874be45466b1a,
        0x1aac285387f65e82c895fc6887ddf40577107454c6ec0317284f033f27d0c785,
        0x25851c3c845d4790f9ddadbdb6057357832e2e7a49775f71ec75a96554d67c77
      )

      pRound(
        0x15a5821565cc2ec2ce78457db197edf353b7ebba2c5523370ddccc3d9f146a67,
        0x2411d57a4813b9980efa7e31a1db5966dcf64f36044277502f15485f28c71727,
        0x002e6f8d6520cd4713e335b8c0b6d2e647e9a98e12f4cd2558828b5ef6cb4c9b
      )

      pRound(
        0x2ff7bc8f4380cde997da00b616b0fcd1af8f0e91e2fe1ed7398834609e0315d2,
        0x00b9831b948525595ee02724471bcd182e9521f6b7bb68f1e93be4febb0d3cbe,
        0x0a2f53768b8ebf6a86913b0e57c04e011ca408648a4743a87d77adbf0c9c3512
      )

      pRound(
        0x00248156142fd0373a479f91ff239e960f599ff7e94be69b7f2a290305e1198d,
        0x171d5620b87bfb1328cf8c02ab3f0c9a397196aa6a542c2350eb512a2b2bcda9,
        0x170a4f55536f7dc970087c7c10d6fad760c952172dd54dd99d1045e4ec34a808
      )

      pRound(
        0x29aba33f799fe66c2ef3134aea04336ecc37e38c1cd211ba482eca17e2dbfae1,
        0x1e9bc179a4fdd758fdd1bb1945088d47e70d114a03f6a0e8b5ba650369e64973,
        0x1dd269799b660fad58f7f4892dfb0b5afeaad869a9c4b44f9c9e1c43bdaf8f09
      )

      pRound(
        0x22cdbc8b70117ad1401181d02e15459e7ccd426fe869c7c95d1dd2cb0f24af38,
        0x0ef042e454771c533a9f57a55c503fcefd3150f52ed94a7cd5ba93b9c7dacefd,
        0x11609e06ad6c8fe2f287f3036037e8851318e8b08a0359a03b304ffca62e8284
      )

      pRound(
        0x1166d9e554616dba9e753eea427c17b7fecd58c076dfe42708b08f5b783aa9af,
        0x2de52989431a859593413026354413db177fbf4cd2ac0b56f855a888357ee466,
        0x3006eb4ffc7a85819a6da492f3a8ac1df51aee5b17b8e89d74bf01cf5f71e9ad
      )

      pRound(
        0x2af41fbb61ba8a80fdcf6fff9e3f6f422993fe8f0a4639f962344c8225145086,
        0x119e684de476155fe5a6b41a8ebc85db8718ab27889e85e781b214bace4827c3,
        0x1835b786e2e8925e188bea59ae363537b51248c23828f047cff784b97b3fd800
      )

      pRound(
        0x28201a34c594dfa34d794996c6433a20d152bac2a7905c926c40e285ab32eeb6,
        0x083efd7a27d1751094e80fefaf78b000864c82eb571187724a761f88c22cc4e7,
        0x0b6f88a3577199526158e61ceea27be811c16df7774dd8519e079564f61fd13b
      )

      pRound(
        0x0ec868e6d15e51d9644f66e1d6471a94589511ca00d29e1014390e6ee4254f5b,
        0x2af33e3f866771271ac0c9b3ed2e1142ecd3e74b939cd40d00d937ab84c98591,
        0x0b520211f904b5e7d09b5d961c6ace7734568c547dd6858b364ce5e47951f178
      )

      pRound(
        0x0b2d722d0919a1aad8db58f10062a92ea0c56ac4270e822cca228620188a1d40,
        0x1f790d4d7f8cf094d980ceb37c2453e957b54a9991ca38bbe0061d1ed6e562d4,
        0x0171eb95dfbf7d1eaea97cd385f780150885c16235a2a6a8da92ceb01e504233
      )

      pRound(
        0x0c2d0e3b5fd57549329bf6885da66b9b790b40defd2c8650762305381b168873,
        0x1162fb28689c27154e5a8228b4e72b377cbcafa589e283c35d3803054407a18d,
        0x2f1459b65dee441b64ad386a91e8310f282c5a92a89e19921623ef8249711bc0
      )

      pRound(
        0x1e6ff3216b688c3d996d74367d5cd4c1bc489d46754eb712c243f70d1b53cfbb,
        0x01ca8be73832b8d0681487d27d157802d741a6f36cdc2a0576881f9326478875,
        0x1f7735706ffe9fc586f976d5bdf223dc680286080b10cea00b9b5de315f9650e
      )

      pRound(
        0x2522b60f4ea3307640a0c2dce041fba921ac10a3d5f096ef4745ca838285f019,
        0x23f0bee001b1029d5255075ddc957f833418cad4f52b6c3f8ce16c235572575b,
        0x2bc1ae8b8ddbb81fcaac2d44555ed5685d142633e9df905f66d9401093082d59
      )

      pRound(
        0x0f9406b8296564a37304507b8dba3ed162371273a07b1fc98011fcd6ad72205f,
        0x2360a8eb0cc7defa67b72998de90714e17e75b174a52ee4acb126c8cd995f0a8,
        0x15871a5cddead976804c803cbaef255eb4815a5e96df8b006dcbbc2767f88948
      )

      pRound(
        0x193a56766998ee9e0a8652dd2f3b1da0362f4f54f72379544f957ccdeefb420f,
        0x2a394a43934f86982f9be56ff4fab1703b2e63c8ad334834e4309805e777ae0f,
        0x1859954cfeb8695f3e8b635dcb345192892cd11223443ba7b4166e8876c0d142
      )

      pRound(
        0x04e1181763050e58013444dbcb99f1902b11bc25d90bbdca408d3819f4fed32b,
        0x0fdb253dee83869d40c335ea64de8c5bb10eb82db08b5e8b1f5e5552bfd05f23,
        0x058cbe8a9a5027bdaa4efb623adead6275f08686f1c08984a9d7c5bae9b4f1c0
      )

      pRound(
        0x1382edce9971e186497eadb1aeb1f52b23b4b83bef023ab0d15228b4cceca59a,
        0x03464990f045c6ee0819ca51fd11b0be7f61b8eb99f14b77e1e6634601d9e8b5,
        0x23f7bfc8720dc296fff33b41f98ff83c6fcab4605db2eb5aaa5bc137aeb70a58
      )

      pRound(
        0x0a59a158e3eec2117e6e94e7f0e9decf18c3ffd5e1531a9219636158bbaf62f2,
        0x06ec54c80381c052b58bf23b312ffd3ce2c4eba065420af8f4c23ed0075fd07b,
        0x118872dc832e0eb5476b56648e867ec8b09340f7a7bcb1b4962f0ff9ed1f9d01
      )

      pRound(
        0x13d69fa127d834165ad5c7cba7ad59ed52e0b0f0e42d7fea95e1906b520921b1,
        0x169a177f63ea681270b1c6877a73d21bde143942fb71dc55fd8a49f19f10c77b,
        0x04ef51591c6ead97ef42f287adce40d93abeb032b922f66ffb7e9a5a7450544d
      )

      pRound(
        0x256e175a1dc079390ecd7ca703fb2e3b19ec61805d4f03ced5f45ee6dd0f69ec,
        0x30102d28636abd5fe5f2af412ff6004f75cc360d3205dd2da002813d3e2ceeb2,
        0x10998e42dfcd3bbf1c0714bc73eb1bf40443a3fa99bef4a31fd31be182fcc792
      )

      pRound(
        0x193edd8e9fcf3d7625fa7d24b598a1d89f3362eaf4d582efecad76f879e36860,
        0x18168afd34f2d915d0368ce80b7b3347d1c7a561ce611425f2664d7aa51f0b5d,
        0x29383c01ebd3b6ab0c017656ebe658b6a328ec77bc33626e29e2e95b33ea6111
      )

      pRound(
        0x10646d2f2603de39a1f4ae5e7771a64a702db6e86fb76ab600bf573f9010c711,
        0x0beb5e07d1b27145f575f1395a55bf132f90c25b40da7b3864d0242dcb1117fb,
        0x16d685252078c133dc0d3ecad62b5c8830f95bb2e54b59abdffbf018d96fa336
      )

      pRound(
        0x0a6abd1d833938f33c74154e0404b4b40a555bbbec21ddfafd672dd62047f01a,
        0x1a679f5d36eb7b5c8ea12a4c2dedc8feb12dffeec450317270a6f19b34cf1860,
        0x0980fb233bd456c23974d50e0ebfde4726a423eada4e8f6ffbc7592e3f1b93d6
      )

      pRound(
        0x161b42232e61b84cbf1810af93a38fc0cece3d5628c9282003ebacb5c312c72b,
        0x0ada10a90c7f0520950f7d47a60d5e6a493f09787f1564e5d09203db47de1a0b,
        0x1a730d372310ba82320345a29ac4238ed3f07a8a2b4e121bb50ddb9af407f451
      )

      pRound(
        0x2c8120f268ef054f817064c369dda7ea908377feaba5c4dffbda10ef58e8c556,
        0x1c7c8824f758753fa57c00789c684217b930e95313bcb73e6e7b8649a4968f70,
        0x2cd9ed31f5f8691c8e39e4077a74faa0f400ad8b491eb3f7b47b27fa3fd1cf77
      )

      pRound(
        0x23ff4f9d46813457cf60d92f57618399a5e022ac321ca550854ae23918a22eea,
        0x09945a5d147a4f66ceece6405dddd9d0af5a2c5103529407dff1ea58f180426d,
        0x188d9c528025d4c2b67660c6b771b90f7c7da6eaa29d3f268a6dd223ec6fc630
      )

      pRound(
        0x3050e37996596b7f81f68311431d8734dba7d926d3633595e0c0d8ddf4f0f47f,
        0x15af1169396830a91600ca8102c35c426ceae5461e3f95d89d829518d30afd78,
        0x1da6d09885432ea9a06d9f37f873d985dae933e351466b2904284da3320d8acc
      )

      pRound(
        0x2796ea90d269af29f5f8acf33921124e4e4fad3dbe658945e546ee411ddaa9cb,
        0x202d7dd1da0f6b4b0325c8b3307742f01e15612ec8e9304a7cb0319e01d32d60,
        0x096d6790d05bb759156a952ba263d672a2d7f9c788f4c831a29dace4c0f8be5f
      )

      fRound(
        0x054efa1f65b0fce283808965275d877b438da23ce5b13e1963798cb1447d25a4,
        0x1b162f83d917e93edb3308c29802deb9d8aa690113b2e14864ccf6e18e4165f1,
        0x21e5241e12564dd6fd9f1cdd2a0de39eedfefc1466cc568ec5ceb745a0506edc
      )

      fRound(
        0x1cfb5662e8cf5ac9226a80ee17b36abecb73ab5f87e161927b4349e10e4bdf08,
        0x0f21177e302a771bbae6d8d1ecb373b62c99af346220ac0129c53f666eb24100,
        0x1671522374606992affb0dd7f71b12bec4236aede6290546bcef7e1f515c2320
      )

      fRound(
        0x0fa3ec5b9488259c2eb4cf24501bfad9be2ec9e42c5cc8ccd419d2a692cad870,
        0x193c0e04e0bd298357cb266c1506080ed36edce85c648cc085e8c57b1ab54bba,
        0x102adf8ef74735a27e9128306dcbc3c99f6f7291cd406578ce14ea2adaba68f8
      )

      {
        let state0 := addmod(mload(0x0), 0x0fe0af7858e49859e2a54d6f1ad945b1316aa24bfbdd23ae40a6d0cb70c3eab1, F)
        let state1 := addmod(mload(0x20), 0x216f6717bbc7dedb08536a2220843f4e2da5f1daa9ebdefde8a5ea7344798d22, F)
        let state2 := addmod(mload(0x80), 0x1da55cc900f0d21f4a3e694391918a1b3c23b2ac773c6b3ef88e2e4228325161, F)

        p := mulmod(state0, state0, F)
        state0 := mulmod(mulmod(p, p, F), state0, F)
        p := mulmod(state1, state1, F)
        state1 := mulmod(mulmod(p, p, F), state1, F)
        p := mulmod(state2, state2, F)
        state2 := mulmod(mulmod(p, p, F), state2, F)

        mstore(0x0, addmod(addmod(mulmod(state0, M00, F), mulmod(state1, M10, F), F), mulmod(state2, M20, F), F))
        return(0, 0x20)
      }
    }
  }
}