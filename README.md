KWNinePatchView
===============

##How-To
You can either simply drag and drop the `KWNinePatchView/KWNinePatchView` folder into your existing project or add the library as a submodule and reference `KWNinePatchView.xcodeproj` from within your own project.

--
1. `#import "KWNinePatchView.h"` wherever you require access to it.

2. Then, Use!
    ``` objective-c
    KWNinePatchView *ninePatchView = [[KWNinePatchView alloc] initWithImage:[UIImage imageNamed:@"button.png"]];
    [ninePatchView setFrame:CGRectMake(30, 30, 148, 88)];
    [self.view addSubview:ninePatchView];
    ```
    
<br />

##Requirements
- Requires Automatic Reference Counting (ARC)

> If you require non-ARC compatibility, you will need to set the `-fobjc-arc` compiler flag on all of the KWNinePatchView source files.

<br />

## Changelog

+ 1.0 First Release.
+ 1.1 Event Target.

<br />

##License

> The MIT License (MIT)
>
>  KWNinePatchView - Copyright (C) 2014, Jeungwon An (kawoou@kawoou.kr)
>
>  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following condi tions:
>
>  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
>  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
