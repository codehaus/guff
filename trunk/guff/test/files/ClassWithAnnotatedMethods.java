package guff.test;

@javax.persistence.Entity
public class ClassWithAnnotatedMethods{

    @javax.persistence.Column(
        name="addressID",
        table="EMP_DETAIL"
    )
    public String getAddressID(){
        return "0";
    }

    @ManyToMany(
        fetch=FetchType.EAGER
    )
    @JoinTable(
        name="CUSTOMERBEANSUBSCRIPTIONBEAN",
        joinColumns=@JoinColumn(
            name="CUSTOMERBEAN_CUSTOMERID96",
            referencedColumnName="customerid"
        ),
        inverseJoinColumns=@JoinColumn(
            name="SUBSCRIPTION_TITLE",
            referencedColumnName="TITLE"
        )
    )
    public abstract Collection getSubscriptions();
}
