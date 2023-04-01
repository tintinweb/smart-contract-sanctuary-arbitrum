// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Owned {
  error Owned_NotOwner();
  error Owned_NotPendingOwner();

  address public owner;
  address public pendingOwner;

  event OwnershipTransferred(
    address indexed _previousOwner,
    address indexed _newOwner
  );

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Owned_NotOwner();
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    // Move _newOwner to pendingOwner
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    // Check
    if (msg.sender != pendingOwner) revert Owned_NotPendingOwner();

    // Log
    emit OwnershipTransferred(owner, pendingOwner);

    // Effect
    owner = pendingOwner;
    delete pendingOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Owned } from "@hmx/base/Owned.sol";
import { PythStructs, IPythEvents } from "pyth-sdk-solidity/IPyth.sol";
import { PythErrors } from "pyth-sdk-solidity/PythErrors.sol";
import { ILeanPyth } from "./interfaces/ILeanPyth.sol";
import { IPyth, IPythPriceInfo, IPythDataSource } from "./interfaces/IPyth.sol";
import { IWormHole } from "./interfaces/IWormHole.sol";
import "./UnsafeBytesLib.sol";

contract LeanPyth is Owned, ILeanPyth {
  // errors
  error LeanPyth_ExpectZeroFee();
  error LeanPyth_OnlyUpdater();
  error LeanPyth_PriceFeedNotFound();
  error LeanPyth_InvalidWormholeVaa();
  error LeanPyth_InvalidUpdateDataSource();

  IPyth public pyth;

  // mapping of our asset id to Pyth's price id
  mapping(bytes32 => IPythPriceInfo) public priceInfos;

  // whitelist mapping of price updater
  mapping(address => bool) public isUpdaters;

  // events
  event LogSetUpdater(address indexed _account, bool _isActive);
  event LogSetPyth(address _oldPyth, address _newPyth);

  /**
   * Modifiers
   */
  modifier onlyUpdater() {
    if (!isUpdaters[msg.sender]) {
      revert LeanPyth_OnlyUpdater();
    }
    _;
  }

  constructor(address _pyth) {
    pyth = IPyth(_pyth);

    // Sanity
    IPyth(pyth).wormhole();
  }

  /// @dev Updates the price feeds with the given price data.
  /// @notice The function must not be called with any msg.value. (Define as payable for IPyth compatability)
  /// @param updateData The array of encoded price feeds to update.
  function updatePriceFeeds(bytes[] calldata updateData) external payable override onlyUpdater {
    // The function is payable (to make it IPyth compat), so there is a chance msg.value is submitted.
    // On LeanPyth, we do not collect any fee.
    if (msg.value > 0) revert LeanPyth_ExpectZeroFee();

    // Loop through all of the price data
    for (uint i = 0; i < updateData.length; ) {
      _updatePriceBatchFromVm(updateData[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Returns the current price for the given price feed ID. Revert if price never got fed.
  /// @param id The unique identifier of the price feed.
  /// @return price The current price.
  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price) {
    IPythPriceInfo storage priceInfo = priceInfos[id];
    if (priceInfo.publishTime == 0) revert LeanPyth_PriceFeedNotFound();

    price.publishTime = priceInfo.publishTime;
    price.expo = priceInfo.expo;
    price.price = priceInfo.price;
    price.conf = priceInfo.conf;
    return price;
  }

  /// @dev Returns the update fee for the given price feed update data.
  /// @return feeAmount The update fee, which is always 0.
  function getUpdateFee(bytes[] calldata /*updateData*/) external pure returns (uint feeAmount) {
    // The update fee is always 0, so simply return 0
    return 0;
  }

  /// @dev Sets the `isActive` status of the given account as a price updater.
  /// @param _account The account address to update.
  /// @param _isActive The new status of the account as a price updater.
  function setUpdater(address _account, bool _isActive) external onlyOwner {
    // Set the `isActive` status of the given account
    isUpdaters[_account] = _isActive;

    // Emit a `LogSetUpdater` event indicating the updated status of the account
    emit LogSetUpdater(_account, _isActive);
  }

  /// @notice Set Pyth address.
  /// @param _newPyth The Pyth address to set.
  function setPyth(address _newPyth) external onlyOwner {
    emit LogSetPyth(address(pyth), _newPyth);

    // Sanity
    IPyth(_newPyth).wormhole();

    pyth = IPyth(_newPyth);
  }

  /// @dev Verifies the validity of a VAA encoded in hexadecimal format.
  /// @param _vaaInHex The hexadecimal encoded VAA to be verified.
  /// @notice revert LeanPyth_InvalidWormholeVaa if the VAA is not valid.
  /// @notice revert LeanPyth_InvalidUpdateDataSource if the VAA's emitter chain ID and address combination is not a valid data source.
  function verifyVaa(bytes memory _vaaInHex) external view {
    IWormHole wormHole = IWormHole(pyth.wormhole());
    (IWormHole.VM memory vm, bool valid, ) = wormHole.parseAndVerifyVM(_vaaInHex);

    if (!valid) revert LeanPyth_InvalidWormholeVaa();

    if (!pyth.isValidDataSource(vm.emitterChainId, vm.emitterAddress)) revert LeanPyth_InvalidUpdateDataSource();
  }

  function _updatePriceBatchFromVm(bytes calldata encodedVm) private {
    // Main difference from original Pyth is here, `.parseVM()` vs `.parseAndVerifyVM()`.
    // On LeanPyth, we skip vaa verification to save gas.
    IWormHole.VM memory vm = IWormHole(pyth.wormhole()).parseVM(encodedVm);
    _parseAndProcessBatchPriceAttestation(vm, encodedVm);
  }

  function _parseAndProcessBatchPriceAttestation(IWormHole.VM memory vm, bytes calldata encodedVm) internal {
    // Most of the math operations below are simple additions.
    // In the places that there is more complex operation there is
    // a comment explaining why it is safe. Also, byteslib
    // operations have proper require.
    unchecked {
      bytes memory encoded = vm.payload;

      (uint index, uint nAttestations, uint attestationSize) = _parseBatchAttestationHeader(encoded);

      // Deserialize each attestation
      for (uint j = 0; j < nAttestations; j++) {
        (IPythPriceInfo memory info, bytes32 priceId) = _parseSingleAttestationFromBatch(
          encoded,
          index,
          attestationSize
        );

        // Respect specified attestation size for forward-compat
        index += attestationSize;

        // Store the attestation
        uint64 latestPublishTime = priceInfos[priceId].publishTime;

        if (info.publishTime > latestPublishTime) {
          priceInfos[priceId] = info;

          emit PriceFeedUpdate(
            priceId,
            info.publishTime,
            info.price,
            info.conf,
            // User can use this data to verify data integrity via .verifyVaa()
            encodedVm
          );
        }
      }

      emit BatchPriceFeedUpdate(vm.emitterChainId, vm.sequence);
    }
  }

  function _parseBatchAttestationHeader(
    bytes memory encoded
  ) internal pure returns (uint index, uint nAttestations, uint attestationSize) {
    unchecked {
      index = 0;

      // Check header
      {
        uint32 magic = UnsafeBytesLib.toUint32(encoded, index);
        index += 4;
        if (magic != 0x50325748) revert PythErrors.InvalidUpdateData();

        uint16 versionMajor = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;
        if (versionMajor != 3) revert PythErrors.InvalidUpdateData();

        // This value is only used as the check below which currently
        // never reverts
        // uint16 versionMinor = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;

        // This check is always false as versionMinor is 0, so it is commented.
        // in the future that the minor version increases this will have effect.
        // if(versionMinor < 0) revert InvalidUpdateData();

        uint16 hdrSize = UnsafeBytesLib.toUint16(encoded, index);
        index += 2;

        // NOTE(2022-04-19): Currently, only payloadId comes after
        // hdrSize. Future extra header fields must be read using a
        // separate offset to respect hdrSize, i.e.:
        //
        // uint hdrIndex = 0;
        // bpa.header.payloadId = UnsafeBytesLib.toUint8(encoded, index + hdrIndex);
        // hdrIndex += 1;
        //
        // bpa.header.someNewField = UnsafeBytesLib.toUint32(encoded, index + hdrIndex);
        // hdrIndex += 4;
        //
        // // Skip remaining unknown header bytes
        // index += bpa.header.hdrSize;

        uint8 payloadId = UnsafeBytesLib.toUint8(encoded, index);

        // Skip remaining unknown header bytes
        index += hdrSize;

        // Payload ID of 2 required for batch headerBa
        if (payloadId != 2) revert PythErrors.InvalidUpdateData();
      }

      // Parse the number of attestations
      nAttestations = UnsafeBytesLib.toUint16(encoded, index);
      index += 2;

      // Parse the attestation size
      attestationSize = UnsafeBytesLib.toUint16(encoded, index);
      index += 2;

      // Given the message is valid the arithmetic below should not overflow, and
      // even if it overflows then the require would fail.
      if (encoded.length != (index + (attestationSize * nAttestations))) revert PythErrors.InvalidUpdateData();
    }
  }

  function _parseSingleAttestationFromBatch(
    bytes memory encoded,
    uint index,
    uint attestationSize
  ) internal pure returns (IPythPriceInfo memory info, bytes32 priceId) {
    unchecked {
      // NOTE: We don't advance the global index immediately.
      // attestationIndex is an attestation-local offset used
      // for readability and easier debugging.
      uint attestationIndex = 0;

      // Unused bytes32 product id
      attestationIndex += 32;

      priceId = UnsafeBytesLib.toBytes32(encoded, index + attestationIndex);
      attestationIndex += 32;

      info.price = int64(UnsafeBytesLib.toUint64(encoded, index + attestationIndex));
      attestationIndex += 8;

      info.conf = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
      attestationIndex += 8;

      info.expo = int32(UnsafeBytesLib.toUint32(encoded, index + attestationIndex));
      attestationIndex += 4;

      info.emaPrice = int64(UnsafeBytesLib.toUint64(encoded, index + attestationIndex));
      attestationIndex += 8;

      info.emaConf = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
      attestationIndex += 8;

      {
        // Status is an enum (encoded as uint8) with the following values:
        // 0 = UNKNOWN: The price feed is not currently updating for an unknown reason.
        // 1 = TRADING: The price feed is updating as expected.
        // 2 = HALTED: The price feed is not currently updating because trading in the product has been halted.
        // 3 = AUCTION: The price feed is not currently updating because an auction is setting the price.
        uint8 status = UnsafeBytesLib.toUint8(encoded, index + attestationIndex);
        attestationIndex += 1;

        // Unused uint32 numPublishers
        attestationIndex += 4;

        // Unused uint32 numPublishers
        attestationIndex += 4;

        // Unused uint64 attestationTime
        attestationIndex += 8;

        info.publishTime = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
        attestationIndex += 8;

        if (status == 1) {
          // status == TRADING
          attestationIndex += 24;
        } else {
          // If status is not trading then the latest available price is
          // the previous price info that are passed here.

          // Previous publish time
          info.publishTime = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
          attestationIndex += 8;

          // Previous price
          info.price = int64(UnsafeBytesLib.toUint64(encoded, index + attestationIndex));
          attestationIndex += 8;

          // Previous confidence
          info.conf = UnsafeBytesLib.toUint64(encoded, index + attestationIndex);
          attestationIndex += 8;
        }
      }

      if (attestationIndex > attestationSize) revert PythErrors.InvalidUpdateData();
    }
  }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 *
 * @notice This is the **unsafe** version of BytesLib which removed all the checks (out of bound, ...)
 * to be more gas efficient.
 */
pragma solidity >=0.8.0 <0.9.0;

library UnsafeBytesLib {
  function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
    bytes memory tempBytes;

    assembly {
      // Get a location of some free memory and store it in tempBytes as
      // Solidity does for memory variables.
      tempBytes := mload(0x40)

      // Store the length of the first bytes array at the beginning of
      // the memory for tempBytes.
      let length := mload(_preBytes)
      mstore(tempBytes, length)

      // Maintain a memory counter for the current write location in the
      // temp bytes array by adding the 32 bytes for the array length to
      // the starting location.
      let mc := add(tempBytes, 0x20)
      // Stop copying when the memory counter reaches the length of the
      // first bytes array.
      let end := add(mc, length)

      for {
        // Initialize a copy counter to the start of the _preBytes data,
        // 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        // Write the _preBytes data into the tempBytes memory 32 bytes
        // at a time.
        mstore(mc, mload(cc))
      }

      // Add the length of _postBytes to the current length of tempBytes
      // and store it as the new length in the first 32 bytes of the
      // tempBytes memory.
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      // Move the memory counter back from a multiple of 0x20 to the
      // actual end of the _preBytes data.
      mc := end
      // Stop copying when the memory counter reaches the new combined
      // length of the arrays.
      end := add(mc, length)

      for {
        let cc := add(_postBytes, 0x20)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }

      // Update the free-memory pointer by padding our last write location
      // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
      // next 32 byte block, then round down to the nearest multiple of
      // 32. If the sum of the length of the two arrays is zero then add
      // one before rounding down to leave a blank 32 bytes (the length block with 0).
      mstore(
        0x40,
        and(
          add(add(end, iszero(add(length, mload(_preBytes)))), 31),
          not(31) // Round down to the nearest 32 bytes.
        )
      )
    }

    return tempBytes;
  }

  function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
    assembly {
      // Read the first 32 bytes of _preBytes storage, which is the length
      // of the array. (We don't need to use the offset into the slot
      // because arrays use the entire slot.)
      let fslot := sload(_preBytes.slot)
      // Arrays of 31 bytes or less have an even value in their slot,
      // while longer arrays have an odd value. The actual length is
      // the slot divided by two for odd values, and the lowest order
      // byte divided by two for even values.
      // If the slot is even, bitwise and the slot with 255 and divide by
      // two to get the length. If the slot is odd, bitwise and the slot
      // with -1 and divide by two.
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)
      let newlength := add(slength, mlength)
      // slength can contain both the length and contents of the array
      // if length < 32 bytes so let's prepare for that
      // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
      switch add(lt(slength, 32), lt(newlength, 32))
      case 2 {
        // Since the new array still fits in the slot, we just need to
        // update the contents of the slot.
        // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
        sstore(
          _preBytes.slot,
          // all the modifications to the slot are inside this
          // next block
          add(
            // we can just add to the slot contents because the
            // bytes we want to change are the LSBs
            fslot,
            add(
              mul(
                div(
                  // load the bytes from memory
                  mload(add(_postBytes, 0x20)),
                  // zero all bytes to the right
                  exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
              ),
              // increase length by the double of the memory
              // bytes length
              mul(mlength, 2)
            )
          )
        )
      }
      case 1 {
        // The stored value fits in the slot, but the combined value
        // will exceed it.
        // get the keccak hash to get the contents of the array
        mstore(0x0, _preBytes.slot)
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // save new length
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // The contents of the _postBytes array start 32 bytes into
        // the structure. Our first read should obtain the `submod`
        // bytes that can fit into the unused space in the last word
        // of the stored array. To get this, we read 32 bytes starting
        // from `submod`, so the data we read overlaps with the array
        // contents by `submod` bytes. Masking the lowest-order
        // `submod` bytes allows us to add that value directly to the
        // stored value.

        let submod := sub(32, slength)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(
          sc,
          add(and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00), and(mload(mc), mask))
        )

        for {
          mc := add(mc, 0x20)
          sc := add(sc, 1)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } {
          sstore(sc, mload(mc))
        }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
      default {
        // get the keccak hash to get the contents of the array
        mstore(0x0, _preBytes.slot)
        // Start copying to the last used word of the stored array.
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // save new length
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // Copy over the first `submod` bytes of the new data as in
        // case 1 above.
        let slengthmod := mod(slength, 32)
        let mlengthmod := mod(mlength, 32)
        let submod := sub(32, slengthmod)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(sc, add(sload(sc), and(mload(mc), mask)))

        for {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } {
          sstore(sc, mload(mc))
        }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
    }
  }

  function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
    uint8 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x1), _start))
    }

    return tempUint;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }

  function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
    uint32 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x4), _start))
    }

    return tempUint;
  }

  function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
    uint64 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x8), _start))
    }

    return tempUint;
  }

  function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
    uint96 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0xc), _start))
    }

    return tempUint;
  }

  function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
    uint128 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x10), _start))
    }

    return tempUint;
  }

  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes32;
  }

  function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(_preBytes)

      // if lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        // cb is a circuit breaker in the for loop since there's
        //  no said feature for inline assembly loops
        // cb = 1 - don't breaker
        // cb = 0 - break
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for {
          let cc := add(_postBytes, 0x20)
          // the next line is the loop condition:
          // while(uint256(mc < end) + cb == 2)
        } eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // if any of these checks fails then arrays are not equal
          if iszero(eq(mload(mc), mload(cc))) {
            // unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }

  function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
    bool success = true;

    assembly {
      // we know _preBytes_offset is 0
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)

      // if lengths don't match the arrays are not equal
      switch eq(slength, mlength)
      case 1 {
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // blank the last byte which is the length
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // unsuccess:
              success := 0
            }
          }
          default {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
            let cb := 1

            // get the keccak hash to get the contents of the array
            mstore(0x0, _preBytes.slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // the next line is the loop condition:
            // while(uint256(mc < end) + cb == 2)
            for {

            } eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IPyth, PythStructs, IPythEvents } from "pyth-sdk-solidity/IPyth.sol";

interface ILeanPyth {
  /// @dev Emitted when the price feed with `id` has received a fresh update.
  /// @param id The Pyth Price Feed ID.
  /// @param publishTime Publish time of the given price update.
  /// @param price Price of the given price update.
  /// @param conf Confidence interval of the given price update.
  /// @param encodedVm The submitted calldata. Use this verify integrity of price data.
  event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf, bytes encodedVm);

  /// @dev Emitted when a batch price update is processed successfully.
  /// @param chainId ID of the source chain that the batch price update comes from.
  /// @param sequenceNumber Sequence number of the batch price update.
  event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);

  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

  function updatePriceFeeds(bytes[] calldata updateData) external payable;

  function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPyth {
  function wormhole() external view returns (address);

  function isValidDataSource(uint16 dataSourceChainId, bytes32 dataSourceEmitterAddress) external view returns (bool);
}

// @notice avoid slither compilation bug by declaring struct outside of interface scope
struct IPythPriceInfo {
  // slot 1
  uint64 publishTime;
  int32 expo;
  int64 price;
  uint64 conf;
  // slot 2
  int64 emaPrice;
  uint64 emaConf;
}

// @notice avoid slither compilation bug by declaring struct outside of interface scope
struct IPythDataSource {
  uint16 chainId;
  bytes32 emitterAddress;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IWormHole {
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 guardianIndex;
  }

  struct VM {
    uint8 version;
    uint32 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    uint64 sequence;
    uint8 consistencyLevel;
    bytes payload;
    uint32 guardianSetIndex;
    Signature[] signatures;
    bytes32 hash;
  }

  function parseAndVerifyVM(
    bytes calldata encodedVM
  ) external view returns (VM memory vm, bool valid, string memory reason);

  function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);
}