/SPDX-License-Identifier: MIT

// deploy on polygon
pragma solidity ^0.8.10;

contract FamilyMultiSigWallet {
    // when ETH is deposited into the wallet
    event Deposit(address indexed sender, uint256 amount);

    // when a transaction is submitted & waiting for other owners to approve
    event Submit(uint256 indexed txId);

    // when other owners approve a transaction
    event Approval(address indexed owner, uint256 indexed txId);

    // when an owner changes their mind on a transaction they may have already approved
    event Revoke(address indexed owner, uint256 indexed txId);

    // when a tranaction is executed after a certain amount of approvals
    event Execute(uint256 indexed txId);

    //this struct Transaction type stores the transaction
    struct Transaction {
        address to; // the address where the transaction is executed
        uint256 value; // the amount of ETH sent to the "to" address
        bytes data; // the data to be sent to the "to" address
        bool executed; // will set this equal to true after execution
    }

    // storing an array of all the transactions
    Transaction[] public transactions;

    // storing the array of owners
    address[] public owners;
    // if an address (e.g. msg.sender) is an owner of the wallet it will return true, otherwise, false
    mapping(address => bool) public isOwner;

    // the number of approvals required before a transaction can be executed
    uint256 public required;

    // storing the tranaction number/id to the approvals, per address
    mapping(uint256 => mapping(address => bool)) public approved;

    // modifier to make sure only the owner can execute a function
    modifier onlyOwner() {
        require(
            isOwner[msg.sender],
            "You are not an owner of the multisig wallet."
        );
        _;
    }

    // modifier to make sure a transaction exists
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist.");
        _;
    }

    // modifier to make sure a transaction has not yet been approved
    modifier notYetApproved(uint256 _txId) {
        require(
            !approved[_txId][msg.sender],
            "Transaction has already been approved."
        );
        _;
    }

    // modifier to make sure a transaction has not yet been executed
    modifier notYetExecuted(uint256 _txId) {
        require(
            !transactions[_txId].executed,
            "Transaction has already been executed."
        );
        _;
    }

    // constructor requires addresses of the owners & the number of approvals required
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "More owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required numnber of owners"
        );

        //saving & adding the _owners in the constructor to the owners state variable
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner.");
            require(!isOwner[owner], "Owner must be unique.");

            isOwner[owner] = true;
            owners.push(owner);
        }

        //initialising the number of approvals required
        required = _required;
    }

    // receive ether
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // a function to allow any of the owners to submit a transaction
    //calldata is cheaper on gas
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );

        emit Submit(transactions.length - 1); // index of the transaction
    }

    // function to allow other owners to approve a transaction
    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notYetApproved(_txId)
        notYetExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approval(msg.sender, _txId);
    }

    // function to count the number of approvals
    // initialising the count variable in the returns output to save gas
    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        // for loop to check if each owner has approved a txId or not
        for (uint256 i; i < owners.length; i++) {
            // if an owner has approved a txId, increment the count
            if (approved[_txId][owners[i]]) {
                count++;
            }
        }
    }

    // function to execute the transaction
    function execute(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notYetExecuted(_txId)
    {
        require(
            _getApprovalCount(_txId) >= required,
            "More approvals are required before execution."
        );
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        // ignoring the second output
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success == true, "Transaction failed.");

        emit Execute(_txId);
    }

    // function for an owner to revoke their approval of a transaction
    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notYetExecuted(_txId)
    {
        //in order to revoke, the caller must first have already approved it
        require(
            approved[_txId][msg.sender],
            "You haven't approved this transaction in the first place."
        );
        approved[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }
}
