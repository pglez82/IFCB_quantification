/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author pablo
 */
@XmlRootElement(name = "question")
@XmlAccessorType (XmlAccessType.FIELD)
public class Question implements Serializable
{
    private String questionText;
    private boolean practical;
    private boolean theory;
    
    @XmlElement(name = "answers")
    private List<Answer> answerList;

    public Question()
    {
        
    }
    
    public Question(String questionText) {
        this.questionText = questionText;
        answerList = new ArrayList<>();
    }
    
    public void addAnswer(Answer answer)
    {
        answerList.add(answer);
    }

    public boolean isPractical() {
        return practical;
    }

    public void setPractical(boolean practical) {
        this.practical = practical;
    }

    public boolean isTheory() {
        return theory;
    }

    public void setTheory(boolean theory) {
        this.theory = theory;
    }
    
    public String getQuestionText() {
        return questionText;
    }

    public void setQuestionText(String questionText) {
        this.questionText = questionText;
    }
    
    public void removeAnswers()
    {
        answerList = new ArrayList<>();
    }
    
    public List<Answer> getAnswerList()
    {
        return new ArrayList<>(answerList);
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final Question other = (Question) obj;
        return Objects.equals(this.questionText, other.questionText);
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 23 * hash + Objects.hashCode(this.questionText);
        hash = 23 * hash + Objects.hashCode(this.answerList);
        return hash;
    }
    
    
}
