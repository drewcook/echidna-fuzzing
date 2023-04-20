pragma solidity ^0.8.0;
import "./token.sol";

contract TestToken is Token {
    constructor() public {
        paused(); // pause the contract
        owner = address(0x0); // lose ownership
    }

    // add the property
    // property testing, test that the function remains paused
    function echidna_cannot_be_unpaused() public view returns (bool) {
        return is_paused;
        // fails due to Owner() then resume()
        // solution is to button-up Owner() by adding the isOwner modifier to the function so that anon can't take ownership
    }

    // assertion testing - more specific, still tests properties
    // difference is we are asseting that the value is a certain value, vs returning it as a boolean expectation
    function testPausable() public {
        assert(is_paused);
    }
}
