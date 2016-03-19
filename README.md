# swiftlets

Open source Swift library focused on project portability and code reuse. No dependencies are allowed and no package managers are ever required.

#### Philosphy

This project is a direct reaction to my experience with libraries, such as Boost for C++, which over time tend to become difficult to integrate because of their internal and external dependencies. 

The rules for swiftlets are very simple:

1) No dependencies. There shall be no dependencies on either non-system libraries or other files in the swiftlets library!

2) See rule #1.

#### License

Following the lead of Swift itself the Apache License is used here. Any submisions must follow the same licensing model. Library authors will be attributed if desired. 

#### Library Organization

The library is organized into portable and platform specific directories. Code that is not generic Swift must be submitted to the appropriate platform directory.

#### Usage

It is suggested you simply checkout the library in a location that can be shared between your projects and referenced from your projects. This allows for tracking updates from GitHub as they are made available. If this does not fit your project model or workflow it should be trivial to copy files into your projects on a case by case basis as there are never any dependencies.  

Because each file is entirely standalone no package managers should be required and there are no plans to add support for package managers. 

