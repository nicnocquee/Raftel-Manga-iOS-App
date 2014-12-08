#import "SnapshotHelper.js"




var target = UIATarget.localTarget();

target.frontMostApp().navigationBar().searchBars()[0].searchBars()[0].tap();
target.delay(1);
target.frontMostApp().keyboard().typeString("one piece");
target.frontMostApp().keyboard().typeString("\n");
target.pushTimeout(10);
target.frontMostApp().mainWindow().collectionViews()[0].cells()["One Piece"].tap();
target.popTimeout();
target.frontMostApp().navigationBar().buttons()["Add"].tap();
captureLocalizedScreenshot('0-name')
target.delay(1);
target.frontMostApp().mainWindow().buttons()["Dismiss"].tap();
target.frontMostApp().navigationBar().buttons()["Ascending"].tap();
target.delay(2);
captureLocalizedScreenshot('0-name')
target.delay(1);
target.frontMostApp().navigationBar().leftButton().tap();
target.delay(2);
captureLocalizedScreenshot('0-name')
target.delay(1);
target.frontMostApp().navigationBar().leftButton().tap();
target.delay(2);
target.frontMostApp().tabBar().buttons()["Collections"].tap();
target.delay(2);
captureLocalizedScreenshot('0-name')
target.delay(1);
target.frontMostApp().tabBar().buttons()["Search"].tap();
target.frontMostApp().navigationBar().searchBars()[0].searchBars()[0].tap();
captureLocalizedScreenshot('0-name')