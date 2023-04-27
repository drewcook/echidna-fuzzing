pragma solidity ^0.5.0;

import "./mintable.sol";

contract Exercise3 is MintableToken {
    constructor() public {
        totalMintable = 10000;
    }

    function testMint() public {
        assert(false);
    }
}
