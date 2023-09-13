// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MultiCall {
    event fail(uint256 indexed index, address indexed sender, bytes result);

    function callTarget(
        address target,
        uint256 _value,
        bytes calldata data
    ) external returns (bool success, bytes memory result) {
        return target.call{value: _value}(data);
    }

    function staticCallTarget(
        address target,
        bytes calldata data
    ) external view returns (bool success, bytes memory result) {
        return target.staticcall(data);
    }

    function multiStaticCallAtomic(
        address[] calldata targets,
        bytes[] calldata data
    ) external view returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(
                data[i]
            );
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }

    function multiStaticCall(
        address[] calldata targets,
        bytes[] calldata data
    ) external view returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");
        bytes[] memory results = new bytes[](data.length);
        for (uint i; i < targets.length; i++) {
            try this.staticCallTarget(targets[i], data[i]) returns (
                bool,
                bytes memory res
            ) {
                results[i] = res;
            } catch {}
        }

        return results;
    }

    function multiCallAtomic(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");
        bytes[] memory results = new bytes[](data.length);
        require(data.length == values.length, "Must same length");
        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call{
                value: values[i]
            }(data[i]);
            require(success, "call failed");
            results[i] = result;
        }
        return results;
    }

    function multiCall(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");
        bytes[] memory results = new bytes[](data.length);
        require(data.length == values.length, "Must same length");
        for (uint i; i < targets.length; i++) {
            bytes memory result;
            try this.callTarget(targets[i], values[i], data[i]) returns (
                bool s,
                bytes memory res
            ) {
                if (!s) {
                    emit fail(i, msg.sender, result);
                }
                results[i] = res;
            } catch {
                emit fail(i, msg.sender, result);
            }
        }
        return results;
    }
}