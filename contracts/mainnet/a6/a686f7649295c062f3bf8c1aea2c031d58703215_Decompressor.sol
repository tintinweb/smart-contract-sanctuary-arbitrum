/**
 *Submitted for verification at Arbiscan on 2023-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Decompressor {
  uint256 constant REFERENCE_INT_BASE = 96;
  uint256 constant REFERENCE_INT_FLOOR_CODE = 32; // " "
  uint256 constant MIN_STRING_LENGTH = 5;
  bytes32 constant HASHED_REFERENCE_PREFIX = 0x15a5de5d00dfc39d199ee772e89858c204d1d545de092db54a345c7303942607;
  bytes1 constant REFERENCE_PREFIX = '`';

  // This could be extended, and deployed once and pay a lot for deployment, but not for computing the keccak everytime in runtime
  function fastGetHash(bytes1 letter) internal pure returns (bytes32) {
    if (letter == 'x') return 0x7521d1cadbcfa91eec65aa16715b94ffc1c9654ba57ea2ef1a2127bca1127a83;
    if (letter == ' ') return 0x681afa780d17da29203322b473d3f210a7d621259a4e6ce9e403f5a266ff719a;
    if (letter == '!') return 0x3275a893b2c93461554cf2a4dd7f413d56decdd6f3fdf0589dbb8bc4fd742386;
    if (letter == '"') return 0x6e9f33448a4153023cdaf3eb759f1afdc24aba433a3e18b683f8c04a6eaa69f0;
    if (letter == '$') return 0xb104e6a8e5e1477c7a8346486401cbd4f10ab4840a4201066d9b59b747cb6f88;
    if (letter == '%') return 0x43b2f7df8a0d3a744d9a3126411ef3787d9e447a59b458310e828119cf8614ad;
    if (letter == "'") return 0xa111f47c4392438c7a3abac74d0f6f440316c2730020cd5facd8390846edb14f;
    if (letter == '&') return 0x88a0fd9b2e9113debae525e4c7cb7bd7bee2110b9507edc0fbc8cb92826bd1db;
    if (letter == '#') return 0xace738c68088218d015fbdce138f062893d86818ac98932f7ce2907c5976fbde;
    if (letter == '(') return 0x484bf06f3118ce360605f902ef526c45207bc469c2b056352f14b8408f9f6f9a;
    if (letter == '-') return 0xd3b8281179950f98149eefdb158d0e1acb56f56e8e343aa9fefafa7e36959561;
    if (letter == '+') return 0x728b8dbbe730d9acd55e30e768e6a28a04bea0c61b88108287c2c87d79c98bb8;
    if (letter == '.') return 0x6f010af653ebe3cb07d297a4ef13366103d392ceffa68dd48232e6e9ff2187bf;
    if (letter == '/') return 0xfba9715e477e68952d3f1df7a185b3708aadad50ec10cc793973864023868527;
    if (letter == ',') return 0x3e7a35b97029f9e0cf6effd71c1a7958822e9a217d3a3aec886668a7dd8231cb;
    if (letter == 'A') return 0x03783fac2efed8fbc9ad443e592ee30e61d65f471140c10ca155e937b435b760;
    if (letter == ')') return 0x59d76dc3b33357eda30db1508968fbb18f21b9cd2442f1559b20154ddaa4d7ed;
    if (letter == 'C') return 0x017e667f4b8c174291d1543c466717566e206df1bfd6f30271055ddafdb18f72;
    if (letter == 'E') return 0x434b529473163ef4ed9c9341d9b7250ab9183c27e7add004c3bba38c56274e24;
    if (letter == 'L') return 0x8aa64f937099b65a4febc243a5ae0f2d6416bb9e473c30dd29c1ee498fb7c5a8;
    if (letter == 'I') return 0x8d61ecf6e15472e15b1a0f63cd77f62aa57e6edcd3871d7a841f1056fb42b216;
    if (letter == 'Q') return 0xfbf3cc6079e09a6a2a778706898aef91b633ff613801d212e0afe7f411ddb1d2;
    if (letter == '>') return 0xeff31f7855752a3582db9a0d965d5063f23d94003e66f8c5a8f8e8fe2ab24753;
    if (letter == 'U') return 0x37bf2238b11b68cdc8382cece82651b59d3c3988873b6e0f33d79694aa45f1be;
    if (letter == 'D') return 0x6c3fd336b49dcb1c57dd4fbeaf5f898320b0da06a5ef64e798c6497600bb79f2;
    if (letter == '[') return 0x9f50164828976b6baa479ea39c718c745bbc0d2521b67dfde8474cbdc9711057;
    if (letter == '*') return 0x04994f67dc55b09e814ab7ffc8df3686b4afb2bb53e60eae97ef043fe03fb829;
    if (letter == 'V') return 0xf0da850a6b7c61a66cdd43ac7529affc6000442af1c1bdda1db3bb7220bf7613;
    if (letter == 'O') return 0xc669aa98d5975cc43653c879a18d9bc4aa8bf51e69f61aeb1d7769216f98009a;
    if (letter == 'Y') return 0x9a2c5f9025f1f0333863704310875ae81a574171bed5b047cfc0f50e347f630e;
    if (letter == 'g') return 0x14bcc435f49d130d189737f9762feb25c44ef5b886bef833e31a702af6be4748;
    if (letter == 'h') return 0xa766932420cc6e9072394bef2c036ad8972c44696fee29397bd5e2c06001f615;
    if (letter == 'Z') return 0x7d54a4ab605dc825939ee59b4af5be4680f51892ef5944365e996fd93f70a2e5;
    if (letter == ']') return 0xb36bcf9cc1d9e7f60b1f757ebd8b4694b17fc592b16065d243c43b09fde00b29;
    if (letter == 'm') return 0xdaba8c984363447d18bf8210079973ac8fc1ce76864315b5baacf246bf6e72f6;
    if (letter == ';') return 0x698f551e2aa42a46289a635eb89f051b273c8603a6b7f8a0d1ba86ca91db4ed8;
    if (letter == 'j') return 0xb31d742db54d6961c6b346af2c9c4c495eb8aff2ebf6b3699e052d1cef5cf50b;
    if (letter == 'l') return 0x6a0d259bd4fb907339fd7c65a133083c1e9554f2ca6325b806612c8df6d7df22;
    if (letter == 'n') return 0x4b4ecedb4964a40fe416b16c7bd8b46092040ec42ef0aa69e59f09872f105cf3;
    if (letter == 'k') return 0xf3d0adcb6a1c70832365e9da0a6b2f5199422f6a53c67cfad171114e3442aa0f;
    if (letter == 'X') return 0x550c64a15031c3064454c19adc6243a6122c138a242eaa098da50bb114fc8d56;
    if (letter == 'u') return 0x32cefdcd8e794145c9af8dd1f4b1fbd92d6e547ae855553080fc8bd19c4883a0;
    if (letter == 'B') return 0x1f675bff07515f5df96737194ea945c36c41e7b4fcef307b7cd4d0e602a69111;
    if (letter == '^') return 0xd44aaa07e74d2fcafe12f68faaa5457fe3eb26e3579823cc5a63d688d25154bb;
    if (letter == 'v') return 0xa147871e98dd2eddde100a3ea8cc6316a0d516adb61013ba565a9cd96e86f510;
    if (letter == 'i') return 0xea00237ef11bd9615a3b6d2629f2c6259d67b19bb94947a1bd739bae3415141c;
    if (letter == 'r') return 0x414f72a4d550cad29f17d9d99a4af64b3776ec5538cd440cef0f03fef2e9e010;
    if (letter == 'o') return 0x53a63b3ee437e1aa804722ac8f2f57053ac47e1bb887f095340cf5990e7faad3;
    if (letter == '{') return 0xa91eddf639b0b768929589c1a9fd21dcb0107199bdd82e55c5348018a1572f52;
    if (letter == '|') return 0xf2736824a8d8680efd16063b669359e760b24936629c9681635556c2b7fa269f;
    if (letter == 't') return 0xcac1bb71f0a97c8ac94ca9546b43178a9ad254c7b757ac07433aa6df35cd8089;
    if (letter == '?') return 0x5f179612d7132c8ed24ba0e286d60d398c4aa1c234eb2274ca1bba47718e9d31;
    if (letter == '=') return 0xf30c17f6c257181e11b9ea19fc7d498b2880fcad645a66e130edeab084271f16;
    if (letter == '~') return 0xa28a3f816fdcab5fa5d9e32081c451a5b738cbc6380020cfae2633e4bd78ded0;
    if (letter == 'J') return 0x90174c907fea3d27ea14230ef6800c7bde0f907fb10d2c747a17af161f784d19;
    if (letter == 'z') return 0x41e406698d040bb44cf693b3dc50c37cf3c854c422d2645b1101662741fbaa88;
    if (letter == '<') return 0x8cb938a03d27235fdf22924e770f8c8a7fc7441e706e979b359839d1efe72520;
    if (letter == 'K') return 0x91cb023ee03dcff3e185aa303e77c329b6b62e0a68a590039a476bc8cb48d055;
    if (letter == '_') return 0xcd5edcba1904ce1b09e94c8a2d2a85375599856ca21c793571193054498b51d7;
    if (letter == 'N') return 0x7c1e3133c5e040bb7fc55cda56e3c1998a2e33373c0850e92b53c932b65ceb44;
    if (letter == 'q') return 0x3ff269d37634c240a40e1b0de0d61faffb6bbb3c251727e2ef176a979d8b95ff;
    if (letter == '@') return 0xe724d40619441ced66a271e59627b7bcd39c77447a4315561b4d21e7b7c9321c;
    if (letter == 'F') return 0xe61d9a3d3848fb2cdd9a2ab61e2f21a10ea431275aed628a0557f9dee697c37a;
    if (letter == 'H') return 0x321c2cb0b0673952956a3bfa56cf1ce4df0cd3371ad51a2c5524561250b01836;
    if (letter == '}') return 0x8e2ffa389f3a6ded42d759b3377ac0d928e6a268d143bcc9517093d10c843bff;
    if (letter == 'S') return 0xa9463b19d1148abedba3d6925530d4465b271ce2cc61f80b1a0a80fd73eab881;
    if (letter == 'T') return 0x846b7b6deb1cfa110d0ea7ec6162a7123b761785528db70cceed5143183b11fc;
    if (letter == 'p') return 0x2304e88f144ae9318c71b0fb9e0f44bd9e0c6c58fb1b5315a35fd8b4b2a444ab;
    if (letter == 's') return 0x60a73bfb121a98fb6b52dfb29eb0defd76b60065b8cf07902baf28c167d24daf;
    if (letter == '') return 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    if (letter == 'w') return 0x01544badb249bb61e3fa1c5ce16e082fa1344cdee4a7389bf5502178c1892d4e;
    if (letter == 'y') return 0x83847cf31c36389df832d0d4d3df7cf28f211e3f83173e5c157bab31573d61f3;
    if (letter == 'G') return 0x077da99d806abd13c9f15ece5398525119d11e11e9836b2ee7d23f6159ad87d2;
    if (letter == 'W') return 0xd2ec75cd002cc54c4cc6690500ee64d030751a1b19466a4ba8be1b42eb5a1031;
    if (letter == 'R') return 0xef22bddd350b943170a67d35191c27e310709a28c38b5762a152ff640108f5b2;
    if (letter == 'P') return 0x7b2ab94bb7d45041581aa3757ae020084674ccad6f75dc3750eb2ea8a92c4e9a;
    if (letter == ':') return 0x96d280011b274d9410ea6c6fc28e2bb076b01d2fac329c49c4b29a719ec4650c;
    if (letter == 'c') return 0x0b42b6393c1f53060fe3ddbfcd7aadcca894465a5a438f69c87d790b2299b9b2;
    if (letter == '5') return 0xceebf77a833b30520287ddd9478ff51abbdffa30aa90a8d655dba0e8a79ce0c1;
    if (letter == '0') return 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
    if (letter == '`') return 0x15a5de5d00dfc39d199ee772e89858c204d1d545de092db54a345c7303942607;
    if (letter == '6') return 0xe455bf8ea6e7463a1046a0b52804526e119b4bf5136279614e0b1e8e296a4e2d;
    if (letter == '7') return 0x52f1a9b320cab38e5da8a8f97989383aab0a49165fc91c737310e4f7e9821021;
    if (letter == '8') return 0xe4b1702d9298fee62dfeccc57d322a463ad55ca201256d01f62b45b2e1c21c10;
    if (letter == '9') return 0xd2f8f61201b2b11a78d6e866abc9c3db2ae8631fa656bfe5cb53668255367afb;
    if (letter == 'e') return 0xa8982c89d80987fb9a510e25981ee9170206be21af3c8e0eb312ef1d3382e761;
    if (letter == 'a') return 0x3ac225168df54212a25c1c01fd35bebfea408fdac2e31ddd6f80a4bbf9a5f1cb;
    if (letter == '1') return 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    if (letter == 'f') return 0xd1e8aeb79500496ef3dc2e57ba746a8315d048b7a664a2bf948db4fa91960483;
    if (letter == '2') return 0xad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5;
    if (letter == 'd') return 0xf1918e8562236eb17adc8502332f4c9c82bc14e19bfc0aa10ab674ff75b3d2f3;
    if (letter == '3') return 0x2a80e1ef1d7842f27f2e6be0972bb708b9a135c38860dbe73c27c3486c34f4de;
    if (letter == '4') return 0x13600b294191fc92924bb3ce4b969c1e7e2bab8f4c93c3fc6d0a51733df3c060;
    if (letter == 'b') return 0xb5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510;
    // if (letter == "\") return 0x731553fa98541ade8b78284229adfe09a819380dee9244baac20dd1e0aa24095;
    // if (letter == bytes2('10')) return 0x1a192fabce13988b84994d4296e6cdc418d55e2f1d7f942188d4040b94fc57ac;
    // console.log(string(abi.encodePacked(letter)));
    return keccak256(abi.encodePacked(letter));
  }
  

  function decodeReferenceInt(bytes memory data, uint256 width) internal pure returns (uint256) {
    uint256 value = 0;
    for (uint256 i = 0; i < width; ) {
      if (i != 0) value *= REFERENCE_INT_BASE;
      uint256 charCode = uint256(uint8(bytes1(data[i])));
      // 127 = REFERENCE_INT_FLOOR_CODE + REFERENCE_INT_BASE - 1
      //   if (charCode >= REFERENCE_INT_FLOOR_CODE && charCode <= 127) {
      value += charCode - REFERENCE_INT_FLOOR_CODE;
      //   } else {
      //     revert('Invalid char code in reference int');
      //   }
      unchecked {
        ++i;
      }
    }
    return value;
  }

  function decodeReferenceLength(bytes memory data) internal pure returns (uint256) {
    return decodeReferenceInt(data, 1) + MIN_STRING_LENGTH;
  }

  function decompress(bytes memory dataAsBytes, uint256 decompressedLength) public pure returns (bytes memory) {
    bytes memory decompressed = new bytes(decompressedLength);
    uint256 dataPointer = 0;
    uint256 decompressedPointer = 0;
    while (dataPointer < bytes(dataAsBytes).length) {
      if (fastGetHash(dataAsBytes[dataPointer]) != HASHED_REFERENCE_PREFIX) {
        decompressed[decompressedPointer] = dataAsBytes[dataPointer];
        unchecked {
          ++dataPointer;
          ++decompressedPointer;
        }
      } else {
        if (fastGetHash(dataAsBytes[dataPointer + 1]) != HASHED_REFERENCE_PREFIX) {
          uint256 distance = decodeReferenceInt(abi.encodePacked(dataAsBytes[dataPointer + 1], dataAsBytes[dataPointer + 2]), 2);
          uint256 length = decodeReferenceLength(abi.encodePacked(dataAsBytes[dataPointer + 3]));
          uint256 start = decompressedPointer - distance - length;
          for (uint256 i = 0; i < length; ) {
            decompressed[decompressedPointer + i] = decompressed[start + i];
            unchecked {
              ++i;
            }
          }
          unchecked {
            decompressedPointer += length;
            dataPointer += MIN_STRING_LENGTH - 1;
          }
        } else {
          decompressed[decompressedPointer] = REFERENCE_PREFIX;
          unchecked {
            ++decompressedPointer;
            dataPointer += 2;
          }
        }
      }
    }
    return decompressed;
  }
  
  function decompressNotPure(bytes memory dataAsBytes, uint256 decompressedLength) public returns (bytes memory) {
      return decompress(dataAsBytes, decompressedLength);
  }
  
  function notDecompress(bytes memory dataAsBytes, uint256 decompressedLength) public returns (bytes memory) {
    return dataAsBytes;
  }
  
}