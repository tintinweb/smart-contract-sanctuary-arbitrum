// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
contract DeresyRequests {
    
  enum QuestionType {Text, Checkbox, SingleChoice}
    
  struct reviewForm {
    string[] questions;
    QuestionType[] questionTypes;
    string[][] choices;
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
    string[] targetsIPFSHashes;
    string formIpfsHash;
    uint256 rewardPerReview;
    Review[] reviews;
    bool isClosed;
    uint256 fundsLeft;
    uint256 reviewFormIndex;
  }

  mapping(string => ReviewRequest) private reviewRequests;

  string[] reviewRequestNames;
  uint256 public reviewFormsTotal;
  
  string public contractVersion = "0.1";

  reviewForm[] reviewForms;

  event CreatedReviewForm(uint256 _formId);
  event CreatedReviewRequest(string _requestName);
  event ClosedReviewRequest(string _requestName);
  event SubmittedReview(string _requestName);

  //creating ReviewForm
  function createReviewForm(string[] memory questions, string[][] memory choices, QuestionType[] memory questionTypes) external  returns (uint256){
    require(questions.length > 0, "Deresy: Questions can't be null");
    require(questionTypes.length > 0, "Deresy: Question Types can't be null");
    require(questionTypes.length == questions.length, "Deresy: Questions and types must have the same length");
    require(questions.length == choices.length, "Deresy: Questions and choices must have the same length");
    reviewForms.push(reviewForm(questions,questionTypes, choices));
    reviewFormsTotal += 1;
    emit CreatedReviewForm(reviewForms.length - 1);
    return reviewForms.length - 1;
  }

  // Creating a request 
  function createRequest(string memory _name, address[] memory reviewers, string[] memory targets, string[] memory targetsIPFSHashes, string memory formIpfsHash, uint256 rewardPerReview, uint256 reviewFormIndex) external payable{
    require(reviewers.length > 0,"Deresy: Reviewers cannot be null");
    require(targets.length > 0,"Deresy: Targets cannot be null");
    require(targetsIPFSHashes.length > 0, "Deresy: Targets IPFS hashes cannot be null");
    require(targets.length == targetsIPFSHashes.length, "Deresy: Targets and targetsIPFSHashes array must have the same length");
    require(reviewFormIndex <= reviewForms.length - 1,"Deresy: ReviewFormIndex invalid");
    require(rewardPerReview > 0,"Deresy: rewardPerReview cannot be empty");
    require(reviewRequests[_name].sponsor == address(0),"Deresy: Name duplicated");
    require(msg.value >= ((reviewers.length * targets.length) * rewardPerReview),"Deresy: msg.value invalid");
    reviewRequests[_name].sponsor = msg.sender;
    reviewRequests[_name].reviewers = reviewers;
    reviewRequests[_name].targets = targets;
    reviewRequests[_name].targetsIPFSHashes = targetsIPFSHashes;
    reviewRequests[_name].formIpfsHash = formIpfsHash;
    reviewRequests[_name].rewardPerReview = rewardPerReview;
    reviewRequests[_name].isClosed = false;
    reviewRequests[_name].fundsLeft = msg.value;
    reviewRequests[_name].reviewFormIndex = reviewFormIndex;
    reviewRequestNames.push(_name);
    emit CreatedReviewRequest(_name);
  }

  function submitReview(string memory _name, uint8 targetIndex, string[] memory answers) external {
    require(reviewRequests[_name].isClosed == false,"Deresy: request closed");
    require(targetIndex < reviewRequests[_name].targets.length,"Deresy: targetIndex invalid");
    require(reviewForms[reviewRequests[_name].reviewFormIndex].questions.length == answers.length,"Deresy: Not the same number of questions and answers");
    require(isReviewer(msg.sender, _name) == true, "This address is not in the reviewers list for the specified request.");
    require(hasSubmittedReview(msg.sender, _name, targetIndex), "This address has already submitted a review for the targte index in the specified request");      
    // validate answer is <= choices.length
    reviewRequests[_name].reviews.push(Review(msg.sender,targetIndex, answers));
    reviewRequests[_name].fundsLeft -= reviewRequests[_name].rewardPerReview;
    payable(msg.sender).transfer(reviewRequests[_name].rewardPerReview);
    emit SubmittedReview(_name);
  }

  function closeReviewRequest(string memory _name) external{
    require(msg.sender == reviewRequests[_name].sponsor, "Deresy: It is not the sponsor");
    require(reviewRequests[_name].isClosed == false,"Deresy: request closed");
    payable(reviewRequests[_name].sponsor).transfer(reviewRequests[_name].fundsLeft);
    reviewRequests[_name].isClosed = true;
    reviewRequests[_name].fundsLeft = 0;
    emit ClosedReviewRequest(_name);
  }

  function getRequest(string memory _name) public view returns (address[] memory reviewers, string[] memory targets, string[] memory targetsIPFSHashes, string memory formIpfsHash, uint256 rewardPerReview,Review[] memory reviews, uint256 reviewFormIndex,bool isClosed){
    ReviewRequest memory request = reviewRequests[_name];
    return (request.reviewers, request.targets, request.targetsIPFSHashes, request.formIpfsHash, request.rewardPerReview, request.reviews, request.reviewFormIndex, request.isClosed);
  }

  function getReviewForm(uint256 _reviewFormIndex) public view returns(string[] memory, QuestionType[] memory, string[][] memory choices){
    return (reviewForms[_reviewFormIndex].questions,reviewForms[_reviewFormIndex].questionTypes, reviewForms[_reviewFormIndex].choices);
  }

  function getReviewRequestsNames() public view returns(string[] memory){
    return reviewRequestNames;
  }

  function isReviewer(address reviewerAddress, string memory _name) internal view returns (bool) {
    bool reviewerFound = false;
    for (uint i = 0; i < reviewRequests[_name].reviewers.length; i++){
      if(reviewRequests[_name].reviewers[i] == reviewerAddress){
        reviewerFound = true;
      }
    }
    return reviewerFound;
  }

  function hasSubmittedReview(address reviewerAddress, string memory _name, uint8 targetIndex) internal view returns (bool) {
    bool notReviewed = true;
    for(uint i = 0; i < reviewRequests[_name].reviews.length; i++) {
      if(reviewRequests[_name].reviews[i].targetIndex == targetIndex && reviewRequests[_name].reviews[i].reviewer == reviewerAddress) {
        notReviewed = false;
      }
    }
    return notReviewed;
  }
}