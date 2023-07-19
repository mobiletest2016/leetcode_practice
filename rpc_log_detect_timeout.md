From: [Leetcode Discussion](https://leetcode.com/discuss/interview-question/924141/google-phone-screen-new-grad)

You have a stream of rpc requests coming in. Each log is of the form {id, timestamp, type(start/end)}. Given a timeout T, you need to figure out at the earliest possible time if a request has timed out.  
Eg :  
id - time - type  
0 - 0 - Start  
1 - 1 - Start  
0 - 2 - End  
2 - 6 - Start  
1 - 7 - End  
Timeout = 3  
Ans : {1, 6} ( figured out id 1 had timed out at time 6 )  
  
I was able to provide an O(nlogn) solution using maps but the interviewer wanted an O(n) solution. I'm thinking maybe using a hashmap with a deque would do it but if anyone else has any solutions please share.
