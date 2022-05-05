/**
 *Submitted for verification at Arbiscan on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
contract DeresyRequests {
    
    enum QuestionType {Text, Checkbox}
    
    struct reviewForm {
        string[] questions;
        QuestionType[] questionTypes;
    }

    struct Review {
      address reviewer;
      uint8 targetIndex;
      string[] answers;
    }
    
    struct ReviewRequest {
      address sponsor;
      address[] reviewers;
      string[] targets;
      string formIpfsHash;
      uint256 rewardPerReview;
      Review[] reviews;
      bool isClosed;
      uint256 fundsLeft;
      uint256 reviewFormIndex;
    }

    mapping(string => ReviewRequest) private reviewRequests;

    string[] public reviewRequestNames;
    uint256 public reviewFormsTotal;

    // mapping(string => Review[]) private reviews;

    reviewForm[] reviewForms;

    //creating ReviewForm
    function createReviewForm(string[] memory questions, QuestionType[] memory questionTypes) external  returns (uint256){
        require(questions.length > 0, "Deresy: Questions can't be null");
        require(questionTypes.length > 0, "Deresy: Question Types can't be null");
        require(questionTypes.length == questions.length, "Deresy: Needs to be the same quantity of parameters");
        reviewForms.push(reviewForm(questions,questionTypes));
        reviewFormsTotal += 1;
        return reviewForms.length - 1;
    }

    // Creating a request 
    function createRequest(string memory _name, address[] memory reviewers, string[] memory targets, string memory formIpfsHash, uint256 rewardPerReview, uint256 reviewFormIndex) external payable{
        require(reviewers.length > 0,"Deresy: Reviewers cannot be null");
        require(reviewFormIndex <= reviewForms.length - 1,"Deresy: ReviewFormIndex invalid");
        require(targets.length == reviewers.length,"Deresy: Needs to be same number of arguments for targets as well for reviewers");
        require(rewardPerReview > 0,"Deresy: rewardPerReview cannot be empty");
        require(reviewRequests[_name].sponsor == address(0),"Deresy: Name duplicated");
        require(msg.value >= ((reviewers.length * targets.length) * rewardPerReview),"Deresy: msg.value invalid");
        reviewRequests[_name].sponsor = msg.sender;
        reviewRequests[_name].reviewers = reviewers;
        reviewRequests[_name].targets = targets;
        reviewRequests[_name].formIpfsHash = formIpfsHash;
        reviewRequests[_name].rewardPerReview = rewardPerReview;
        reviewRequests[_name].isClosed = false;
        reviewRequests[_name].fundsLeft = msg.value;
        reviewRequests[_name].reviewFormIndex = reviewFormIndex;
        reviewRequestNames.push(_name);
    }

    function submitReview(string memory _name, uint8 targetIndex, string[] memory answers) external {
      require(reviewRequests[_name].isClosed == false,"Deresy: request closed");
      require(targetIndex < reviewRequests[_name].targets.length,"Deresy: targetIndex invalid");
      require(reviewForms[reviewRequests[_name].reviewFormIndex].questions.length == answers.length,"Deresy: Not the same number of questions and answers");
      // require(reviewRequests[_name].fundsLeft < reviewRequests[_name].rewardPerReview, "Deresy: Funds are less than reward");
      // bool flag = false;
      for (uint i = 0; i < reviewRequests[_name].reviewers.length; i++){
        if(reviewRequests[_name].reviewers[i] == msg.sender){
          reviewRequests[_name].reviews.push(Review(msg.sender,targetIndex, answers));
          reviewRequests[_name].fundsLeft -= reviewRequests[_name].rewardPerReview;
          payable(msg.sender).transfer(reviewRequests[_name].rewardPerReview);
        }
      }
    }

    function closeReviewRequest(string memory _name) external{
        // require(reviewRequests[_name].name, "Deresy: name does not exist");
        require(msg.sender == reviewRequests[_name].sponsor, "Deresy: Its is not the sponsor");
        require(reviewRequests[_name].isClosed == false,"Deresy: request closed");
        require(reviewRequests[_name].isClosed == true || reviewRequests[_name].isClosed == false, "Deresy: Name does not exist");
        payable(reviewRequests[_name].sponsor).transfer(reviewRequests[_name].fundsLeft);
        reviewRequests[_name].isClosed = true;
        reviewRequests[_name].fundsLeft = 0;
    }

    function getRequest(string memory _name) public view returns (address[] memory reviewers,string[] memory targets,string memory formIpfsHash,uint256 rewardPerReview,Review[] memory review,uint256 reviewFormIndex, bool isClosed){
        return (reviewRequests[_name].reviewers,reviewRequests[_name].targets,reviewRequests[_name].formIpfsHash,reviewRequests[_name].rewardPerReview, reviewRequests[_name].reviews, reviewRequests[_name].reviewFormIndex, reviewRequests[_name].isClosed);
    }

    function getReviewForm(uint256 _reviewFormIndex) public view returns(string[] memory, QuestionType[] memory){
        return (reviewForms[_reviewFormIndex].questions,reviewForms[_reviewFormIndex].questionTypes);
    }

    // function check2(string memory _name) public view returns(address){
    //     for (uint i = 0; i < reviewRequests[_name].reviews.length; i++){
            
    //         return reviewRequests[_name].reviews[i].reviewer;
    //     }
    // }

}