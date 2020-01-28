pragma solidity >=0.5.11 <0.6.2;

import "./SimpleToken.sol";
import "./Bank.sol";

contract Democracy {
    uint256 public minimumQuorum;
    uint256 public debatingPeriod;
    SimpleToken public token;
    Bank public bank;
    Proposal[] public proposals;
    uint256 public numProposals;
    uint256 public now;

    event ProposalAdded(
        uint256 proposalID,
        address recipient,
        uint256 amount,
        bytes data,
        string description
    );
    event Voted(
        uint256 proposalID,
        int256 position,
        address voter,
        uint256 share
    );
    event Joined(address member, uint256 share);
    event Withdrew(address member, uint256 share);

    event ProposalTallied(
        uint256 proposalID,
        int256 result,
        uint256 quorum,
        bool active
    );

    struct Proposal {
        address recipient;
        uint256 amount;
        bytes data;
        string description;
        uint256 creationDate;
        bool active;
        Vote[] votes;
        mapping(address => bool) voted;
    }

    struct Vote {
        int256 position;
        address voter;
    }

    constructor(SimpleToken _voterShareAddress, address _bankAddress) public {
        bank = Bank(_bankAddress);
        token = _voterShareAddress;
        minimumQuorum = 1;
        debatingPeriod = 1 minutes;
    }

    function setBlockTime(uint256 val) public {
        now = val;
    }

    function join() external payable {
        require(msg.value > 0, "User must pay for tokens");
        token.mint(msg.sender, msg.value);
        emit Joined(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 _tokens = token.balanceOf(msg.sender);
        token.withdraw(msg.sender, _tokens);
        emit Withdrew(msg.sender, _tokens);
    }

    function newProposal(
        address _recipient,
        uint256 _amount,
        bytes calldata _data,
        string calldata _description
    ) external returns (uint256 proposalID) {
        if (token.balanceOf(msg.sender) > 0) {
            proposalID = proposals.length++;
            Proposal storage p = proposals[proposalID];
            p.recipient = _recipient;
            p.amount = _amount;
            p.data = _data;
            p.description = _description;
            p.creationDate = now;
            p.active = true;
            emit ProposalAdded(
                proposalID,
                _recipient,
                _amount,
                _data,
                _description
            );
            numProposals = proposalID + 1;
        }
    }

    function getVotesLen(uint256 _proposalID) public view returns (uint256) {
        Proposal storage p = proposals[_proposalID];
        return p.votes.length;
    }

    function hasVoted(uint256 _proposalID, address _voter)
        public
        view
        returns (bool)
    {
        if (_voter == address(0)) {
            _voter = msg.sender;
        }
        Proposal storage p = proposals[_proposalID];
        return p.voted[_voter];
    }

    function vote(uint256 _proposalID, int256 _position)
        external
        returns (uint256 voteID)
    {
        uint256 _share = token.balanceOf(msg.sender);
        if (_share > 0 && (_position >= -1 || _position <= 1)) {
            Proposal storage p = proposals[_proposalID];
            if (p.voted[msg.sender] == true) {
                return 0;
            }
            voteID = p.votes.length++;
            // token.approve(address(bank), _share);
            // token.transferFrom(msg.sender, address(bank), _share);
            p.votes[voteID] = Vote({position: _position, voter: msg.sender});
            p.voted[msg.sender] = true;
            emit Voted(_proposalID, _position, msg.sender, _share);
        }
    }

    function executeProposal(uint256 _proposalID)
        external
        returns (int256 result)
    {
        Proposal storage p = proposals[_proposalID];
        /* Check if debating period is over */
        if (p.active) {
            uint256 quorum = 0;
            /* tally the votes */
            for (uint256 i = 0; i < p.votes.length; ++i) {
                Vote memory v = p.votes[i];
                uint256 share = token.balanceOf(v.voter);
                quorum += share;
                result += int256(share) * v.position;
            }
            /* execute result */
            if (quorum > minimumQuorum && result > 0) {
                for (uint256 i = 0; i < p.votes.length; ++i) {
                    Vote memory v = p.votes[i];
                    uint256 share = token.balanceOf(v.voter);
                    token.transferFrom(v.voter, p.recipient, share);
                }

                p.active = false;
            } else if (quorum > minimumQuorum && result < 0) {
                p.active = false;
            }
            emit ProposalTallied(_proposalID, result, quorum, p.active);
        }
    }
}
