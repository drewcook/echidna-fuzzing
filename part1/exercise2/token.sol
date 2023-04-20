pragma solidity ^0.8.0;

contract Ownership {
    address owner = msg.sender;

    // BUG: allows any anon to take ownership
    // FIXME: remove this function, or add isOwner modifier
    // function Owner() public isOwner {
    //     owner = msg.sender;
    // }

    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }
}

contract Pausable is Ownership {
    bool is_paused;

    modifier ifNotPaused() {
        require(!is_paused);
        _;
    }

    function paused() public isOwner {
        is_paused = true;
    }

    function resume() public isOwner {
        is_paused = false;
    }
}

contract Token is Pausable {
    mapping(address => uint) public balances;

    function transfer(address to, uint value) public ifNotPaused {
        balances[msg.sender] -= value;
        balances[to] += value;
    }
}
