// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NewsRegistry
 * @dev Stores source URLs and publisher names efficiently.
 * Uses a mapping and incremental ID to track news sources.
 */
contract NewsRegistry {
    address public owner;
    uint256 public nextSourceId;

    // Struct to hold the core data
    struct NewsSource {
        string url;
        string publisher;
    }

    // Mapping of source ID to the NewsSource struct
    mapping(uint256 => NewsSource) public sources;
    
    // NEW: Mapping to find the source ID using the URL hash (bytes32).
    // This allows for O(1) lookup efficiency based on the URL.
    mapping(bytes32 => uint256) public urlHashToSourceId;

    event SourceRegistered(uint256 indexed id, string url, string publisher);
    // Added an event for successful lookups, primarily for debugging/indexing off-chain
    // The event will be kept but not emitted in view functions.
    event SourceLookedUp(uint256 indexed id, bytes32 indexed urlHash); 

    constructor() {
        owner = msg.sender;
        nextSourceId = 1; // Start IDs from 1
    }

    // Function to register a new source. Uses 'calldata' for gas efficiency.
    function registerSource(
        string calldata _url,
        string calldata _publisher
    ) external {
        require(msg.sender == owner, "Only owner can register.");

        // Calculate the unique hash for the URL using keccak256
        bytes32 urlHash = keccak256(bytes(_url));
        
        // Ensure the URL is not already registered
        require(urlHashToSourceId[urlHash] == 0, "URL already registered.");

        // Store the current ID mapped to the URL hash for easy retrieval
        urlHashToSourceId[urlHash] = nextSourceId;

        // Create the new source struct (this is the expensive SSTORE operation)
        NewsSource storage newSource = sources[nextSourceId];
        newSource.url = _url;
        newSource.publisher = _publisher;
        
        emit SourceRegistered(nextSourceId, _url, _publisher);

        // Increment ID for the next entry
        nextSourceId++;
    }

    // Getter function to retrieve source data by ID
    function getSource(uint256 _id) external view returns (string memory, string memory) {
        NewsSource storage source = sources[_id];
        require(bytes(source.url).length > 0, "Source ID not found.");
        return (source.url, source.publisher);
    }

    /**
     * @notice Getter function to retrieve source data using the URL.
     * @param _url The source URL to look up.
     * @return The URL and Publisher name.
     */
    function getSourceByUrl(string calldata _url) external view returns (string memory, string memory) {
        // Compute hash of the URL provided by the user
        bytes32 urlHash = keccak256(bytes(_url));
        
        // Look up the source ID using the hash
        uint256 sourceId = urlHashToSourceId[urlHash];

        require(sourceId != 0, "URL not found in registry.");

        // Retrieve the data using the found ID
        NewsSource storage source = sources[sourceId];
        
        // emit SourceLookedUp(sourceId, urlHash); // REMOVED: view functions cannot emit events

        return (source.url, source.publisher);
    }
}