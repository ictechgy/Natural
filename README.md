# Natural   
      
&nbsp;   
      
## 🤔 본 어플리케이션을 만들게된 계기 (What made me create this application?)
   
&nbsp;   
   
## 💻 개발 기간 (Development Period)
   
&nbsp;   
   
## 📚 사용한 라이브러리 (Used libraries)     
1. RxSwift
2. RxCocoa
3. Naver NMapsMap(네이버 맵)
4. Google Firebase 및 Firestore
5. GeoFire 
   
&nbsp;   
   
## 🚀 사용했거나 사용하려 했던 패턴/스킬 (Used Or Tried Patterns And Skills)
1. RxSwift with MVVM
2. DelegateProxy with DelegateProxyType
   
&nbsp;   
   
## 💦 만들면서 힘들었던 점 (Difficulties)
1. RxSwift에 대한 이해   
RxSwift 공부는 곰튀김님 유튜브 강의로 시작하였었다. 들으면서 이해하는 것도 어려웠지만 직접 사용하는 것은 확실히 더 어려웠다.   
내가 느낀 장점: 기존에 (클로저를 넘겨주는 방식으로) @escaping resultHandler를 구현하던 것을 Observable로 바꿔보니 코드는 더 간결해졌다.(나중에 다시 봐도 훨씬 가독성이 좋음. 특히 클로저를 쓰다보면 retain cycle을 신경써줘야 하는 경우가 많았는데 이게 편해졌다.)   
2. Code Refactoring (Delegate 패턴을 DelegateProxy 이용하여 리팩토링)   
RxSwift만큼이나 어려웠던 DelegateProxy..   
Delegate 패턴은 많이 쓰이긴 하지만 RxSwift의 Observable스타일과는 맞지 않는다. 이를 해결해 주는 것이 바로 DelegateProxy다. (Delegate를 감싸서(?) Observable하게 다룰 수 있도록 해준다. fake delegate object) 
   
&nbsp;   
   
## 💬 기능(사용법) 
   
&nbsp;   
   
## 🛠 개선해야할 점/추가했으면 하는 기능 (Needs to be improved / Want to add)
   
&nbsp;   
   
## 📝 Information
   
&nbsp;   
   
