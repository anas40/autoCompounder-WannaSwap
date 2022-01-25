// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWannaFarm {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _ref
    ) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint _pid, address _user) external view returns (uint256, uint256);
}