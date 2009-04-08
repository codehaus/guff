package guff.test;

public class ClassWithMethods{

    private static final String getName(){
        return "Fred";
    }

    protected boolean isHappy(String name,pkg.Person p,pkg.Friend f){
        if(f.hasMoney()){
            if(p.hasHealth()){
                return true;
            }
        }
        return false;
    }
}
