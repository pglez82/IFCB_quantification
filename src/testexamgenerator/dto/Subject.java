/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.dto;

import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author pablo
 */
@XmlRootElement(name = "subject")
@XmlAccessorType (XmlAccessType.FIELD)
public class Subject 
{
    @XmlElement(name = "units")
    private List<Unit> listUnits;

    public Subject() {
    }
    
    
    
    public Subject(List<Unit> listUnits)
    {
        this.listUnits = listUnits;
    }

    public List<Unit> getListUnits() {
        return listUnits;
    }

    public void setListUnits(List<Unit> listUnits) {
        this.listUnits = listUnits;
    }
    
    
    
}
