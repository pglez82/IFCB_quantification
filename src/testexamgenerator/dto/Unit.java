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
import java.util.Random;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import testexamgenerator.logic.exception.NotEnoughQuestionsException;

/**
 *
 * @author pablo
 */
@XmlRootElement(name = "unit")
@XmlAccessorType (XmlAccessType.FIELD)
public class Unit implements Serializable
{
    private static final long serialVersionUID = 4593859946977290574L;
    private String unitName;
    @XmlElement(name = "questions")
    private List<Question> listQuestions;

    public Unit()
    {
        listQuestions = new ArrayList<>();
    }
    
    public Unit(String unitName) {
        this.unitName = unitName;
        listQuestions = new ArrayList<>();
    }
    
    public void addQuestion(Question question,int position)
    {
        listQuestions.add(position,question);
    }
    
    public void removeQuestion(int questionIndex)
    {
        listQuestions.remove(questionIndex);
    }
    
    public List<Question> getRandomQuestions(int numberOfQuestions,boolean theoryQuestions,boolean practicalQuestions) throws NotEnoughQuestionsException
    {
        Random random = new Random(System.currentTimeMillis());
        List<Question> questionList = new ArrayList<>();
        List<Question> candidateQuestions = new ArrayList<>();
        for (Question question : listQuestions)
        {
            if (question.isPractical() && practicalQuestions)
                candidateQuestions.add(question);
            if (question.isTheory() && theoryQuestions)
                candidateQuestions.add(question);
        }
        if (candidateQuestions.size()>=numberOfQuestions)
        {
            while (questionList.size()<numberOfQuestions)
            {
                Question question = candidateQuestions.get(random.nextInt(candidateQuestions.size()));
                if (question.isPractical() == practicalQuestions && question.isTheory() == theoryQuestions)
                    if (!questionList.contains(question))
                        questionList.add(question);
            }

            return questionList;
        }
        else
        {
            throw new NotEnoughQuestionsException("Unit "+unitName+" needs "+numberOfQuestions+" questions but you only have "+candidateQuestions.size()+" questions.");
        }
    }
    
    public List<Question> getSortedQuestions()
    {
        return new ArrayList<>(listQuestions);
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final Unit other = (Unit) obj;
        return Objects.equals(this.unitName, other.unitName);
    }

    @Override
    public int hashCode() {
        int hash = 3;
        hash = 41 * hash + Objects.hashCode(this.unitName);
        hash = 41 * hash + Objects.hashCode(this.listQuestions);
        return hash;
    }

    @Override
    public String toString() {
        return unitName;
    }
}