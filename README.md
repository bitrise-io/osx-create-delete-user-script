create-user-in-osx-script
=========================

For more info and additional options and tips:
* http://apple.stackexchange.com/questions/82472/what-steps-are-needed-to-create-a-new-user-from-the-command-line-on-mountain-lio

# Important
For better user isolation the create user script now creates a new group too, based on the username and assigns the user to this special group.

# Isolation TODO
- users can still ls each others home folder (can't the subfolders?)
- users can "Su" to other users
- user uid and group gid generation is not concurrent safe