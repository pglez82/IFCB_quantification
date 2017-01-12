/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.dto;

import java.io.Serializable;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author pablo
 */
@XmlRootElement(name = "answer")
@XmlAccessorType (XmlAccessType.FIELD)
public class Answer implements Serializable
{
    private String answerText;
    private boolean correct;

    public Answer()
    {
        
    }
    
    public Answer(String answerText, boolean correct) {
        this.answerText = answerText;
        this.correct = correct;
    }

    public String getAnswerText() {
        return answerText;
    }

    public boolean isCorrect() {
        return correct;
    }
}
