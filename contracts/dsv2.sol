// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedLibrary {
    
    struct Book {
        uint256 bookId;
        string title;
        address owner;
        address currentBorrower;
        bool isAvailable;
        uint256 depositAmount;
        uint256 borrowedAt;
        uint256 dueDate;
    }
    
    struct User {
        uint256 reputationScore;
        uint256 totalBooksLent;
        uint256 totalBooksBorrowed;
        bool isRegistered;
    }
    
    mapping(uint256 => Book) public books;
    mapping(address => User) public users;
    mapping(address => uint256[]) public userBooks;
    
    uint256 public bookCounter;
    uint256 public constant LENDING_PERIOD = 14 days;
    
    event BookListed(uint256 indexed bookId, string title, address indexed owner, uint256 depositAmount);
    event BookBorrowed(uint256 indexed bookId, address indexed borrower, uint256 dueDate);
    event BookReturned(uint256 indexed bookId, address indexed borrower, bool onTime);
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    // Function 1: Register user and list a book
    function listBook(string memory _title, uint256 _depositAmount) external {
        // Auto-register user if not registered
        if (!users[msg.sender].isRegistered) {
            users[msg.sender].isRegistered = true;
            users[msg.sender].reputationScore = 100; // Starting reputation
        }
        
        bookCounter++;
        
        books[bookCounter] = Book({
            bookId: bookCounter,
            title: _title,
            owner: msg.sender,
            currentBorrower: address(0),
            isAvailable: true,
            depositAmount: _depositAmount,
            borrowedAt: 0,
            dueDate: 0
        });
        
        userBooks[msg.sender].push(bookCounter);
        users[msg.sender].totalBooksLent++;
        
        emit BookListed(bookCounter, _title, msg.sender, _depositAmount);
    }
    
    // Function 2: Borrow a book with deposit
    function borrowBook(uint256 _bookId) external payable onlyRegistered {
        Book storage book = books[_bookId];
        
        require(book.bookId != 0, "Book does not exist");
        require(book.isAvailable, "Book is not available");
        require(book.owner != msg.sender, "Cannot borrow your own book");
        require(msg.value == book.depositAmount, "Incorrect deposit amount");
        
        book.isAvailable = false;
        book.currentBorrower = msg.sender;
        book.borrowedAt = block.timestamp;
        book.dueDate = block.timestamp + LENDING_PERIOD;
        
        users[msg.sender].totalBooksBorrowed++;
        
        emit BookBorrowed(_bookId, msg.sender, book.dueDate);
    }
    
    // Function 3: Return a book and manage deposit/reputation
    function returnBook(uint256 _bookId) external onlyRegistered {
        Book storage book = books[_bookId];
        
        require(book.currentBorrower == msg.sender, "You are not the borrower");
        require(!book.isAvailable, "Book is already returned");
        
        bool onTime = block.timestamp <= book.dueDate;
        
        // Update reputation scores
        if (onTime) {
            users[msg.sender].reputationScore += 5;
            users[book.owner].reputationScore += 3;
        } else {
            users[msg.sender].reputationScore -= 10;
        }
        
        // Return deposit
        uint256 depositToReturn = book.depositAmount;
        if (!onTime) {
            // Penalize late return - 20% goes to owner
            uint256 penalty = (depositToReturn * 20) / 100;
            payable(book.owner).transfer(penalty);
            depositToReturn -= penalty;
        }
        
        payable(msg.sender).transfer(depositToReturn);
        
        // Reset book status
        book.isAvailable = true;
        book.currentBorrower = address(0);
        book.borrowedAt = 0;
        book.dueDate = 0;
        
        emit BookReturned(_bookId, msg.sender, onTime);
    }
    
    // Helper function: Get user's listed books
    function getUserBooks(address _user) external view returns (uint256[] memory) {
        return userBooks[_user];
    }
    
    // Helper function: Get user reputation
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputationScore;
    }
}
contract address 0x34b26d8741CAddeC53A7A106a1fF4a4C13D6A37d
