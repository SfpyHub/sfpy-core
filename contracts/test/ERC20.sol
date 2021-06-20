// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../SfpyERC20.sol';

contract ERC20 is SfpyERC20 {
  constructor(uint _totalSupply) {
    _mint(msg.sender, _totalSupply);
  }
}