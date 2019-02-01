/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.logic.exception;

/**
 *
 * @author pablo
 */
public class NotEnoughQuestionsException extends Exception {

    /**
     * Creates a new instance of <code>NotEnoughQuestionsException</code>
     * without detail message.
     */
    public NotEnoughQuestionsException() {
    }

    /**
     * Constructs an instance of <code>NotEnoughQuestionsException</code> with
     * the specified detail message.
     *
     * @param msg the detail message.
     */
    public NotEnoughQuestionsException(String msg) {
        super(msg);
    }
}
