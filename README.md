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
2. DelegateProxy with DelegateProxyType (Delegate 패턴 썼던 것 리팩토링)   
   
&nbsp;   
   
## 💦 만들면서 힘들었던 점 (Difficulties)
1. RxSwift에 대한 이해   
RxSwift 공부는 곰튀김님 유튜브 강의로 시작하였었다. 들으면서 이해하는 것도 어려웠지만 직접 사용하는 것은 확실히 더 어려웠다.   
내가 느낀 장점: 기존에 (클로저를 넘겨주는 방식으로) @escaping resultHandler를 구현하던 것을 Observable로 바꿔보니 코드는 더 간결해졌다.(나중에 다시 봐도 훨씬 가독성이 좋음. 특히 클로저를 쓰다보면 retain cycle을 신경써줘야 하는 경우가 많았는데 이게 편해졌다.)   
2. Code Refactoring (Delegate 패턴을 DelegateProxy 이용하여 리팩토링)   
RxSwift만큼이나 어려웠던 DelegateProxy..   
Delegate 패턴은 많이 쓰이긴 하지만 RxSwift의 Observable스타일과는 맞지 않는다. 이를 해결해 주는 것이 바로 DelegateProxy다. (Delegate를 감싸서(?) Observable하게 다룰 수 있도록 해준다. fake delegate object)   
3. Google Firestore와 GeoFire의 호환성 문제    
이 문제 때문에 처음에 많이 헤맸다. 최신 Google FireStore에는 GeoFire를 덧붙일 수가 없었다.(의존성 문제로 인해 GeoFire 4.1.0에는 Google FirebaseFirestore 1.x 설치가 필요했었다. - Firebase 라이브러리의 경우 6.x - 현재는 GeoFire에서 의존성 설정을 업데이트 해서 7.x 까지 가능하다. Google API 라이브러리별 버전의 경우 이후에 구글에서 한가지로 통합하였다. - 원래는 라이브러리별로 버전이 달랐다. - )       
다행히도 pod이 의존성들을 다 고려해서 설치해준 덕분에 큰 고생은 하지 않았다.   
4. Storyboard Autolayout    
Autolayout에 대해 아직 완벽히 숙지하지 못했다. 공부를 더 해야 할 것 같다.(코드를 이용하여 동적으로 설정하는 것도..)    
5. 커스텀 뷰(Custom View)   
6. RxSwift에 대한 부족한 이해    
flatMap operator를 통해 클로저 내부에서 별도의 Observable 데이터를 return하여 메인(바깥) 시퀀스에 싣는 경우 이는 시퀸스의 분기가 아니다. (분기인줄 알았다.)    
내부 Observable의 데이터 자체를 추출해서 메인 시퀀스에 놓는 것이라고 보면 될 듯 하다. *따라서 flatMap을 통해 추출되는 데이터가 error인 경우 메인 시퀀스에도 영향을 미친다.*   
+ **이에 대한 참고 링크**   
  - [RxSwift Issue](https://github.com/ReactiveX/RxSwift/issues/1162)   
  - [곰튀김님 유튜브 - Stream의 분기와 병합](https://www.youtube.com/watch?v=YSYnETTi1pE&t=406s)   
+ 이와는 별도로 참고하면 좋은 링크   
  - [eungding - Signal과 Driver의 차이](https://eunjin3786.tistory.com/75)

&nbsp;   
   
## 💬 기능(사용법) 
   
&nbsp;   
   
## 🛠 개선해야할 점/추가했으면 하는 기능 (Needs to be improved / Want to add)
   
&nbsp;   
   
## 📝 Information
   
&nbsp;   
   
