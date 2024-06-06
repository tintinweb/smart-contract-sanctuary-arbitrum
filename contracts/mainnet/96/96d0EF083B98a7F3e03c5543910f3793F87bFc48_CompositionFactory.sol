// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './interfaces/CompositionInterface.sol';

contract CompositionContract {
  Composition public composition;

  constructor(Composition memory composition_) {
    composition.id = composition_.id;
    composition.user_id = composition_.user_id;
    composition.name = composition_.name;
    composition.composition_type = composition_.composition_type;
    composition.original = composition_.original;
    composition.single_author = composition_.single_author;
    composition.genres = composition_.genres;
    composition.moods = composition_.moods;
    composition.instruments = composition_.instruments;
    composition.voices = composition_.voices;
    composition.details = composition_.details;

    for (uint i = 0; i < composition_.composition_users.length; i++) composition.composition_users.push(composition_.composition_users[i]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './Composition.sol';

error CompositionFactory_InvalidOwner();

contract CompositionFactory {
  event CompositionCreated(address indexed compositionAddress, uint256 indexed id);

  address public owner;
  CompositionContract[] public compositions;

  modifier onlyOwner() {
    if(owner != msg.sender) revert CompositionFactory_InvalidOwner();
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function create(Composition memory composition_) public onlyOwner {
    CompositionContract composition = new CompositionContract(composition_);
    compositions.push(composition);

    emit CompositionCreated(address(composition), composition_.id);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct CompositionUser {
  uint256 id;
  uint256 composition_id;
  string name;
  string user_rol;
  string td;
  string ipi;
  string phone;
  string email;
}

struct CompositionDetails {
  string composition_process;
  string composition_content;
  string description;
  string iswc;
  string isrc;
  bool lyrics;
  bool colab;
  string audio;
  string cover;
  string sheet;
  string download;
  string cover_license;
  string extended_license;
  string author_rights;
  string colab_address;
}

struct Composition {
  uint256 id;
  uint256 user_id;
  string name;
  string composition_type;
  bool original;
  bool single_author;
  string[] genres;
  string[] moods;
  string[] instruments;
  string[] voices;
  CompositionDetails details;
  CompositionUser[] composition_users;
}